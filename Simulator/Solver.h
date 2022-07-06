#include "../State.h"

#pragma once
//#define NOMINMAX
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wmismatched-tags"
#pragma clang diagnostic ignored "-Wreorder"

#include <Eigen/Dense>
#include <Eigen/Sparse>
#include <Eigen/IterativeLinearSolvers>

#pragma GCC diagnostic pop

#include "vega/volumetricMesh/volumetricMesh.h"

#include "EnergyFunction.h"

#include <future>

using Vec   = Eigen::VectorXd;
using SpMat = Eigen::SparseMatrix<double>;

struct loadVal
{
	double t, f;
};


class Solver
{
	VolumetricMesh* mesh;
	uint32_t numDOFs, numElements, numVertices;

    EnergyFunction* energyFunction;

    double lambda, mu;

    Mat3 Twist[3];
    double sq2inv;

    // time integration variables
    double T, h, h2, magicConstant;
    int numSubsteps;

    // boundary conditions
    double loadStep;
    std::vector<uint32_t> BCs;
    int loadedVert;
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

	void StartUp(const Config& config);
	void ShutDown();

	Vec Step(uint32_t selectedVert);

//	void ProcessMessage(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam);

private:
	void ComputeElementJacobianAndHessian(int i);
	void AddToKeff(const Mat12& dPdx, int elem);

	void FillFint();
	void FillKeff();

	Mat3	ComputeDm(int i);
	Mat9x12 ComputedFdx(Mat3 DmInv);

};

