package gmx;
using StringTools;
import tools.StringBuilder;

/**
 * SfGmx offers tools for parsing and printing GameMaker's XML-based GMX files.
 * Indentation and formatting rules are kept binary identical.
 * @author YellowAfterlife
 */
class SfGmx {
	//
	public var name:String;
	public var text:String;
	public var textAsFloat(get, never):Float;
	private inline function get_textAsFloat():Float {
		return Std.parseFloat(text);
	}
	public var textAsInt(get, never):Int;
	private inline function get_textAsInt():Int {
		return Std.parseInt(text);
	}
	//
	public var children:Array<SfGmx> = [];
	private var attrList:Array<String> = [];
	private var attrMap:Map<String, String> = new Map();
	public function new(name:String, text:String = null) {
		this.name = name;
		this.text = text;
	}
	//
	public inline function addChild(q:SfGmx):Void {
		children.push(q);
	}
	public inline function removeChild(q:SfGmx):Void {
		children.remove(q);
	}
	//
	/** Finds the first element with given name */
	public function find(name:String):SfGmx {
		for (q in children) if (q.name == name) return q;
		return null;
	}
	/** Finds the first element with given name and returns it's text, otherwise returns null */
	public function findText(name:String):String {
		for (q in children) if (q.name == name) return q.text;
		return null;
	}
	/** Finds all elements with given name */
	public function findAll(name:String):Array<SfGmx> {
		var r = [];
		for (q in children) if (q.name == name) r.push(q);
		return r;
	}
	/** Finds all elements with given name, including in child nodes */
	public function findRec(name:String, ?r:Array<SfGmx>):Array<SfGmx> {
		if (r == null) r = [];
		for (q in children) {
			if (q.name == name) r.push(q);
			q.findRec(name, r);
		}
		return r;
	}
	//
	public inline function get(attr:String):String {
		return attrMap[attr];
	}
	public function set(attr:String, value:String):Void {
		if (!attrMap.exists(attr)) attrList.push(attr);
		attrMap.set(attr, value);
	}
	public inline function exists(attr:String):Bool {
		return attrMap.exists(attr);
	}
	public function remove(attr:String):Bool {
		if (attrMap.exists(attr)) {
			attrMap.remove(attr);
			attrList.remove(attr);
			return true;
		} else return false;
	}
	//
	private function toStringRec(r:StringBuilder, t:String) {
		if (children.length == 0 && text == null) {
			r.addFormat("<%s/>", name);
			return;
		}
		r.addChar("<".code);
		r.addString(name);
		for (attr in attrList) {
			r.addFormat(' %s="%s"', attr, attrMap[attr].htmlEscape(true));
		}
		r.addChar(">".code);
		var n = children.length;
		if (n > 0) {
			var t1 = t + "  ";
			for (i in 0 ... n) {
				r.add("\r\n");
				r.add(t1);
				children[i].toStringRec(r, t1);
			}
			r.add("\r\n");
			r.add(t);
		} else r.add(text.htmlEscape());
		r.addFormat('</%s>', name);
	}
	
	/** */
	@:keep public function toString() {
		var b = new StringBuilder();
		toStringRec(b, "");
		return b.toString();
	}
	
	/** Converts to a string with a GM-specific header, ready to write. */
	public function toGmxString() {
		var b = new StringBuilder();
		b.addString("<!--This Document is generated by GameMaker, if you edit it by hand then you do so at your own risk!-->\r\n");
		toStringRec(b, "");
		b.addString("\r\n");
		return b.toString();
	}
	
	/** Recursively converts a XML node to GMX. */
	public static function fromXml(xml:Xml):SfGmx {
		var gmx = new SfGmx(xml.nodeName);
		for (a in xml.attributes()) {
			gmx.attrList.push(a);
			gmx.attrMap.set(a, xml.get(a));
		}
		for (q in xml.elements()) {
			gmx.children.push(fromXml(q));
		}
		if (gmx.children.length == 0) {
			var q = xml.firstChild();
			if (q != null) gmx.text = q.nodeValue;
		}
		return gmx;
	}
	
	/** Parses from given XML string, returns top-level node (e.g. <project>). */
	public static function parse(code:String) {
		var xml = Xml.parse(code);
		return fromXml(xml.firstElement());
	}
	//
}