#include "ID.h"

static ID nextID = 0;

ID GetID() { return nextID++; }
