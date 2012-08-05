// MSIE 8 doesn't support Array.prototype.filter
// From: http://stackoverflow.com/questions/2722159/javascript-how-to-filter-object-array-based-on-attributes
// https://developer.mozilla.org/en-US/docs/JavaScript/Reference/Global_Objects/Array/filter

if (!Array.prototype.filter) {
  Array.prototype.filter = function(fun /*, thisp*/) {
    var len = this.length >>> 0;
    if (typeof fun != "function")
    throw new TypeError();

    var res = [];
    var thisp = arguments[1];
    for (var i = 0; i < len; i++) {
      if (i in this) {
        var val = this[i]; // in case fun mutates this
        if (fun.call(thisp, val, i, this))
        res.push(val);
      }
    }
    return res;
  };
}
