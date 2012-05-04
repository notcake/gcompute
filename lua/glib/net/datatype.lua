GLib.Net.DataType =
{
	UInt8	= 0,
	UInt16	= 1,
	UInt32	= 2,
	Int8	= 3,
	Int16	= 4,
	Int32	= 5,
	Float	= 6,
	Double	= 7,
	String	= 8
}
GLib.InvertTable (GLib.Net.DataType)

GLib.Net.DataTypeSizes =
{
	UInt8	= 1,
	UInt16	= 2,
	UInt32	= 4,
	Int8	= 1,
	Int16	= 2,
	Int32	= 4,
	Float	= 4,
	Double	= 8,
	String	= function (str) return str:len () + 1 end
}