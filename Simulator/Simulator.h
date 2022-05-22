#pragma once
#define NOMINMAX

//#include "Renderer.h"

#include <string>
#include "json.hpp"
using json = nlohmann::json;

#include "Solver.h"

class Simulator
{
//	GG::Geometry* surfaceGeo;

	std::vector<Vec> posArray;

	uint32_t numDOFs;
	int stepNum;

	json* config;

public:
	Simulator() = default;
	~Simulator()= default;

	void StartUp(json* config);
	void ShutDown();

	void Update();

//	void ProcessMessage(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam);
};

