GLib.Net.DataType =
{
	UInt8	= 0,
	UInt16	= 1,
	UInt32	= 2,
	UInt64	= 3,
	Int8	= 4,
	Int16	= 5,
	Int32	= 6,
	Int64	= 7,
	Float	= 8,
	Double	= 9,
	String	= 10,
	Boolean	= 11
}
GLib.InvertTable (GLib.Net.DataType)

GLib.Net.DataTypeSizes =
{
	Boolean	= 1,
	UInt8	= 1,
	UInt16	= 2,
	UInt32	= 4,
	UInt64	= 8,
	Int8	= 1,
	Int16	= 2,
	Int32	= 4,
	Int64	= 8,
	Float	= 4,
	Double	= 8,
	String	= function (str) return str:len () + 1 end
}