#include "Config.h"

#pragma once
//#define NOMINMAX
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wmismatched-tags"
#pragma clang diagnostic ignored "-Wreorder"

#include <Eigen/Dense>
#include <Eigen/Sparse>
#include <Eigen/IterativeLinearSolvers>

#pragma GCC diagnostic pop

//#include <Eigen/PardisoSupport>

#include "vega/volumetricMesh/volumetricMesh.h"

#include "EnergyFunction.h"
//#include "json.hpp"
//using json = nlohmann::json;

//#include "PerformanceCounter.h"

//#include <tbb/tbb.h> 

#include <future>

using Vec   = Eigen::VectorXd;
using SpMat = Eigen::SparseMatrix<double>;

struct loadVal
{
	double t, f;
};

class Interpolator
{
	std::vector<loadVal> vals;

public:
	Interpolator() = default;
	~Interpolator() = default;
	
//	void set(json* config)
//	{
//		vals.clear();
//		for (int i = 0; i < (*config)["sim"]["loadCases"]["loadSteps"].size(); ++i)
//		{
//			loadVal val;
//			val.t = (*config)["sim"]["loadCases"]["loadSteps"][i]["t"];
//			val.f = (*config)["sim"]["loadCases"]["loadSteps"][i]["f"];
//			vals.push_back(val);
//		}
//	}
//
//	double get(double T)
//	{
//		int i = 0;
//		//while (false) {
//		while (vals[ i + 1 ].t < T) {
//			if (i < vals.size())
//			{
//				i++;
//			}
//		}
//		double t0 = vals[ i ].t;
//		double f0 = vals[ i ].f;
//
//		double t1 = vals[ i + 1 ].t;
//		double f1 = vals[ i + 1 ].f;
//
//		return f0 + (T - t0) * ((f1 - f0) / (t1 - t0));
//	}
};

enum Integrator { qStatic, bwEuler, Newmark };

class Solver
{
//	json* config;

	VolumetricMesh* mesh;
	uint32_t numDOFs, numElements, numVertices;

	int interactiveVert;
	double interactiveLoad;
	Vec3 interactiveVector;

	Integrator integrator;
	EnergyFunction* energyFunction;

	double lambda, mu;

	Mat3 Twist[3];
	double sq2inv;

	// time integration variables
	double T, h, h2, magicConstant;
	int numSubsteps;
	double alpha, beta;

	// boundary conditions
	std::vector<uint32_t> loadedVerts, BCs;
	SpMat S;
	
	// matrices and vectors
	SpMat Keff, M, spI;
	Vec x_0, u, x, v, a, z, fInt, fExt;

	// precomputed stuff
	std::vector<double> tetVols;
	std::vector<Mat3> DmInvs;
	std::vector<Mat9x12> dFdxs;

	// for parallel Keff building
	std::vector<int> indexArray;
	std::vector<Vec12>	fIntArray;
	std::vector<Mat12>	KelArray;

	// linear solver objects
	Eigen::ConjugateGradient<SpMat, Eigen::Lower | Eigen::Upper> solver;
	//Eigen::PardisoLU<SpMat> solver;

	double FTime, PTime, dPdxTime;

public:
	Solver() = default;
	~Solver() = default;

	void StartUp(const Config& initialConfig);
	void ShutDown();

	Vec Step();

//	void ProcessMessage(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam);

private:
	void ComputeElementJacobianAndHessian(int i);
	void AddToKeff(const Mat12& dPdx, int elem);

	void FillFint();
	void FillKeff();

	Mat3	ComputeDm(int i);
	Mat9x12 ComputedFdx(Mat3 DmInv);

};

