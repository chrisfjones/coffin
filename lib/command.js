(function() {
  var CoffeeScript, commander, exec, exports, fs, path, spawn, writeJsonTemplate, _ref;

  fs = require('fs');

  path = require('path');

  commander = require('commander');

  CoffeeScript = require('coffee-script');

  _ref = require('child_process'), spawn = _ref.spawn, exec = _ref.exec;

  commander.version('0.0.1');

  commander.usage('[options] <coffeecloud template>');

  commander.option('-o, --output [dir]', 'Directory to output compiled file(s) to');

  commander.option('--pretty', 'Add spaces and stuff to the resulting json to make it a little prettier');

  commander.option('-p --print', 'Print the compiled template');

  commander.parse(process.argv);

  exports = module.exports.run = function() {
    var pre, source, _i, _len, _ref2, _results;
    pre = "require('./coffeecloud') ->\n";
    _ref2 = commander.args;
    _results = [];
    for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
      source = _ref2[_i];
      _results.push(fs.readFile(source, function(err, code) {
        var base, compiled, line, tabbedLines, template, templateString;
        if (err) throw err;
        base = commander.output || path.dirname(source);
        tabbedLines = (function() {
          var _j, _len2, _ref3, _results2;
          _ref3 = code.toString().split('\n');
          _results2 = [];
          for (_j = 0, _len2 = _ref3.length; _j < _len2; _j++) {
            line = _ref3[_j];
            _results2.push('  ' + line);
          }
          return _results2;
        })();
        tabbedLines.push('  return');
        code = tabbedLines.join('\n');
        code = pre + code;
        compiled = CoffeeScript.compile(code, {
          source: source,
          bare: true
        });
        template = eval(compiled);
        templateString = commander.pretty ? JSON.stringify(template, null, 2) : JSON.stringify(template);
        if (commander.print) {
          return console.log(templateString);
        } else {
          return writeJsonTemplate(source, templateString, base);
        }
      }));
    }
    return _results;
  };

  writeJsonTemplate = function(source, json, base) {
    var filename, templatePath, write;
    filename = path.basename(source, path.extname(source)) + '.template';
    templatePath = path.join(base, filename);
    write = function() {
      if (json.length <= 0) json = ' ';
      return fs.writeFile(templatePath, json, function(err) {
        if (err) console.err(err.message);
        return console.log("wrote " + templatePath);
      });
    };
    return path.exists(base, function(exists) {
      if (exists) {
        return write();
      } else {
        return exec("mkdir -p " + base, write);
      }
    });
  };

}).call(this);
