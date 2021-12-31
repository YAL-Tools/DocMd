package dmd.auto;

enum abstract DocMdAutoFieldKind(Int) {
	var Flat;
	var StaticVar;
	var StaticFunc;
	var InstVar;
	var InstVarFQ;
	var InstFunc;
	var Constructor;
	var EnumCtr;
}