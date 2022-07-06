#include "Solver.h"

#include "vega/volumetricMesh/volumetricMeshLoader.h"

#include <cstdlib>
#include <ctime>
#include <iomanip>


void Solver::StartUp(const Config& config)
{
    const Config::Simulator& simConfig = config.simulator;
    // read config
    {
		h				= simConfig.h;
		h2				= h * h;
        magicConstant   = simConfig.magicConstant;
        loadStep        = simConfig.loadStep;
        loadedVert      = simConfig.loadedVert;

		solver.setMaxIterations(simConfig.maxCGIteration);

        // load mesh
		{
			std::string meshPath = config.bundlePath + std::string{'/'} + config.simulator.modelName + ".veg";
			std::cout << "loading mesh " << meshPath << '\n';

			mesh = VolumetricMeshLoader::load(meshPath.c_str());

			if (!mesh)
			{
				std::cout << "fail! terminating\n";
				std::exit(420);
			}
            std::cout << "success! num elements: "
                << mesh->getNumElements()
                << ";  num vertices: "
                << mesh->getNumVertices() << ";\n";
		}

		// set material
		{
			const double E = simConfig.material.E * 1.e6;
			const double nu = simConfig.material.nu;

            energyFunction = new ARAP{ E, nu };
            lambda = nu * E / ((1.0 + nu) * (1.0 - 2.0 * nu)); // from vega fem homogeneousNeoHookeanIsotropicMaterial.cpp
            mu = E / (2.0 * (1.0 + nu));

            Twist[0].setZero();
            Twist[0](0, 1) = -1.0;
            Twist[0](1, 0) = 1.0;

            Twist[1].setZero();
            Twist[1](1, 2) = 1.0;
            Twist[1](2, 1) = -1.0;

            Twist[2].setZero();
            Twist[2](0, 2) = 1.0;
            Twist[2](2, 0) = -1.0;

            sq2inv = 1.0 / std::sqrt(2.0);
		}

        BCs = simConfig.BCs;
	}

    numVertices = mesh->getNumVertices();
	numDOFs = 3 * numVertices;
    numElements = mesh->getNumElements();

	T = 0.0;

	x.setZero(numDOFs);
	x_0.setZero(numDOFs);
	u.setZero(numDOFs);
	v.setZero(numDOFs);
	a.setZero(numDOFs);
	z.setZero(numDOFs);
	fExt.setZero(numDOFs);

	// DmInv, dFdx, mass
	{
		DmInvs.reserve(numElements);
		dFdxs.reserve(numElements);
		tetVols.reserve(numElements);

		M = SpMat(numDOFs, numDOFs);

		const double rho = simConfig.material.rho;
		for (int i = 0; i < numElements; ++i)
		{
			Mat3 Dm = ComputeDm(i);

			Mat3 DmInv = Dm.inverse();
			DmInvs.emplace_back(DmInv);

			Mat9x12 dFdx = ComputedFdx(DmInv);
			dFdxs.emplace_back(dFdx);

			// tetVols, M mx.
			{
				double vol = std::abs((1.0 / 6) * Dm.determinant());
				tetVols.emplace_back(vol);
				double mass = rho * vol;
				for (int v = 0; v < 4; ++v)
				{
                    int index = mesh->getVertexIndex(i, v);
					M.coeffRef(3 * index + 0, 3 * index + 0) += mass;
					M.coeffRef(3 * index + 1, 3 * index + 1) += mass;
					M.coeffRef(3 * index + 2, 3 * index + 2) += mass;
				}
			}

		}
	}

	// create Keff, tbb arrays
	{
		Keff = SpMat(numDOFs, numDOFs);

		for (int i = 0; i < numElements; ++i)
		{
			{
				indexArray.push_back(3 * mesh->getVertexIndex(i, 0));
				indexArray.push_back(3 * mesh->getVertexIndex(i, 1));
				indexArray.push_back(3 * mesh->getVertexIndex(i, 2));
				indexArray.push_back(3 * mesh->getVertexIndex(i, 3));
			}

			Mat12 m;
			m.setZero();

			AddToKeff(m, i);
		}

		fIntArray = std::vector<Vec12>{ numElements, Vec12::Zero() };
		KelArray  = std::vector<Mat12>{ numElements, Mat12::Zero() };
	}

    for (int i = 0; i < mesh->getNumVertices(); ++i)
    {
        Vec3d v = mesh->getVertex(i);
        x(3 * i + 0) = v[0];
        x(3 * i + 1) = v[1];
        x(3 * i + 2) = v[2];
    }
	x_0 = x;
}

void Solver::ShutDown()
{
	delete mesh;
}

Vec Solver::Step()
{
	T += h;

	fExt.setZero();

    static float load = 0;
        load += loadStep;
    if (load < -2000000)
        load = 1500000;

	fExt(3 * loadedVert + 1) += load;

    // clear Keff to 0.0
    for (int k = 0; k < Keff.outerSize(); ++k)
        for (Eigen::SparseMatrix<double>::InnerIterator it(Keff, k); it; ++it)
            it.valueRef() = 0.0;

    fInt.setZero(numDOFs);

    // build Keff
    FTime = PTime = dPdxTime = 0.0;

    for (int i = 0; i < numElements; i++)
        ComputeElementJacobianAndHessian(i);

    // accumulating Keff and fInt
    {
        std::thread KeffThread{ &Solver::FillKeff, this };
        std::thread FintThread{ &Solver::FillFint, this };

        FintThread.join();
        KeffThread.join();

    }

    Vec SystemVec =  -fInt + fExt;

    for (const auto& bc : BCs)
    {
        const int index = 3 * bc;
        Keff.coeffRef(index + 0, index + 0) = 1.0;
        Keff.coeffRef(index + 1, index + 1) = 1.0;
        Keff.coeffRef(index + 2, index + 2) = 1.0;

        SystemVec(index + 0) = 0.0;
        SystemVec(index + 1) = 0.0;
        SystemVec(index + 2) = 0.0;
    }

    solver.compute(Keff);
    Vec u = solver.solve(SystemVec);

    const double constant = magicConstant * h;
    x.noalias() += constant * u;

    return x;
}

void Solver::ComputeElementJacobianAndHessian(int i)
{
	const int* indices = &(indexArray[4 * i]);

	Mat3 F;
	{
		Vec3 v0, v1, v2, v3;
		{
			v0 << x(indices[0] + 0), x(indices[0] + 1), x(indices[0] + 2);
			v1 << x(indices[1] + 0), x(indices[1] + 1), x(indices[1] + 2);
			v2 << x(indices[2] + 0), x(indices[2] + 1), x(indices[2] + 2);
			v3 << x(indices[3] + 0), x(indices[3] + 1), x(indices[3] + 2);
		}
		const Vec3 ds1 = v1 - v0;
		const Vec3 ds2 = v2 - v0;
		const Vec3 ds3 = v3 - v0;

		Mat3 Ds;
		Ds <<
			ds1[0], ds2[0], ds3[0],
			ds1[1], ds2[1], ds3[1],
			ds1[2], ds2[2], ds3[2];
		const Mat3 DmInv = DmInvs[i];
		F = Ds * DmInv;
	}

	Mat3 P;
	// ARAP
	Mat3 U, VT, R;
	Vec3 Sigma;
	{
		using namespace Eigen;
		JacobiSVD<Mat3, NoQRPreconditioner> SVD(F, ComputeFullU | ComputeFullV);
		Sigma = SVD.singularValues();
		U = SVD.matrixU();
		VT = SVD.matrixV();
		VT.transposeInPlace();

		R = U * VT;
		P = mu * (F - R);
	}

	const Mat9x12 dFdx = dFdxs[i];
	const Mat12x9 minusTetVolxdFdxT = -tetVols[i] * dFdx.transpose();
	// calculate forces
	{
		const Vec9 Pv = Flatten(P);

		const Vec12 fEl = minusTetVolxdFdxT * Pv;

		fIntArray[i] = fEl;
	}

	Mat9 dPdF;
	//ARAP
	{
		double I[3];
		I[0] = Sigma(0) + Sigma(1);
		I[1] = Sigma(1) + Sigma(2);
		I[2] = Sigma(0) + Sigma(2);

		double lambda[3];
		for (int i = 0; i < 3; ++i)
			(I[i] >= 2.0) ? lambda[i] = 2.0 / I[i] : lambda[i] = 1.0;

		dPdF.setIdentity();
		for (int el = 0; el < 3; ++el)
		{
			Mat3 Q = sq2inv * U * Twist[el] * VT;

			Vec9 q = Flatten(Q);
			Mat9 H = lambda[el] * q * q.transpose();
			dPdF -= H;
		}
		dPdF *= 2.0;


	}

	const Mat12 dPdx = minusTetVolxdFdxT * dPdF * dFdx;

	KelArray[i] = dPdx;

}

void Solver::FillFint()
{
	for (int i = 0; i < numElements; ++i)
	{
		int* indices = &(indexArray[4 * i]);

		for (int el = 0; el < 4; ++el)
			for (int incr = 0; incr < 3; ++incr)
				fInt(indices[el] + incr) += fIntArray[i](3 * el + incr);
	}
}

void Solver::FillKeff()
{
	for (int i = 0; i < numElements; ++i)
	{
		int* indices = &(indexArray[4 * i]);

		for (int y = 0; y < 4; ++y)
			for (int x = 0; x < 4; ++x)
				for (int innerY = 0; innerY < 3; ++innerY)
					for (int innerX = 0; innerX < 3; ++innerX)
						Keff.coeffRef(indices[x] + innerX, indices[y] + innerY) += KelArray[i](3 * x + innerX, 3 * y + innerY);

	}
}

void Solver::AddToKeff(const Mat12& dPdx, int elem)
{
	int* indices = &(indexArray[4*elem]);
	for (int y = 0; y < 4; ++y)
		for (int x = 0; x < 4; ++x)
			for (int innerX = 0; innerX < 3; ++innerX)
				for (int innerY = 0; innerY < 3; ++innerY)
					Keff.coeffRef(indices[x] + innerX, indices[y] + innerY) += dPdx(3 * x + innerX, 3 * y + innerY);
}

Mat3 Solver::ComputeDm(int i)
{
    Vec3d v0 = mesh->getVertex(i, 0);
    Vec3d v1 = mesh->getVertex(i, 1);
    Vec3d v2 = mesh->getVertex(i, 2);
    Vec3d v3 = mesh->getVertex(i, 3);

	Vec3d dm1 = v1 - v0;
	Vec3d dm2 = v2 - v0;
	Vec3d dm3 = v3 - v0;

	Mat3 Dm;
	Dm.setZero();
	Dm <<
		dm1[0], dm2[0], dm3[0],
		dm1[1], dm2[1], dm3[1],
		dm1[2], dm2[2], dm3[2];

	return Dm;
}

Mat9x12 Solver::ComputedFdx(Mat3 DmInv)
{
	const double m = DmInv(0, 0);
	const double n = DmInv(0, 1);
	const double o = DmInv(0, 2);
	const double p = DmInv(1, 0);
	const double q = DmInv(1, 1);
	const double r = DmInv(1, 2);
	const double s = DmInv(2, 0);
	const double t = DmInv(2, 1);
	const double u = DmInv(2, 2);

	const double t1 = -m - p - s;
	const double t2 = -n - q - t;
	const double t3 = -o - r - u;

	Mat9x12 dFdx;
	dFdx.setZero();

	dFdx(0, 0) = t1;
	dFdx(0, 3) = m;
	dFdx(0, 6) = p;
	dFdx(0, 9) = s;
	dFdx(1, 1) = t1;
	dFdx(1, 4) = m;
	dFdx(1, 7) = p;
	dFdx(1, 10) = s;
	dFdx(2, 2) = t1;
	dFdx(2, 5) = m;
	dFdx(2, 8) = p;
	dFdx(2, 11) = s;
	dFdx(3, 0) = t2;
	dFdx(3, 3) = n;
	dFdx(3, 6) = q;
	dFdx(3, 9) = t;
	dFdx(4, 1) = t2;
	dFdx(4, 4) = n;
	dFdx(4, 7) = q;
	dFdx(4, 10) = t;
	dFdx(5, 2) = t2;
	dFdx(5, 5) = n;
	dFdx(5, 8) = q;
	dFdx(5, 11) = t;
	dFdx(6, 0) = t3;
	dFdx(6, 3) = o;
	dFdx(6, 6) = r;
	dFdx(6, 9) = u;
	dFdx(7, 1) = t3;
	dFdx(7, 4) = o;
	dFdx(7, 7) = r;
	dFdx(7, 10) = u;
	dFdx(8, 2) = t3;
	dFdx(8, 5) = o;
	dFdx(8, 8) = r;
	dFdx(8, 11) = u;

	return dFdx;
}
