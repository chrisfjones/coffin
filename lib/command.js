(function() {
  var CoffeeScript, commander, exec, exports, fs, path, spawn, validateArgs, writeJsonTemplate, _ref;

  fs = require('fs');

  path = require('path');

  commander = require('commander');

  CoffeeScript = require('coffee-script');

  _ref = require('child_process'), spawn = _ref.spawn, exec = _ref.exec;

  commander.version('0.0.2');

  commander.usage('[options] <coffin template>');

  commander.option('-o, --output [dir]', 'Directory to output compiled file(s) to');

  commander.option('--pretty', 'Add spaces and stuff to the resulting json to make it a little prettier');

  commander.option('-p --print', 'Print the compiled template');

  commander.option('--cloudFormationHome [dir]', 'The home of your AWS Cloudformation tools. Defaults to your AWS_CLOUDFORMATION_HOME environment variable.');

  commander.option('--validate', 'Validates the generated template. Either an AWS_CLOUDFORMATION_HOME environment variable or a --cloudFormationHome switch is required.');

  commander.parse(process.argv);

  exports = module.exports.run = function() {
    var pre, source, _i, _len, _ref2, _results;
    if (!validateArgs()) {
      commander.usage();
      return;
    }
    pre = "require('coffin') ->\n";
    _ref2 = commander.args;
    _results = [];
    for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
      source = _ref2[_i];
      _results.push(fs.readFile(source, function(err, code) {
        var base, compiled, line, tabbedLines, template, templateString;
        if (err) {
          console.error("" + source + " not found");
          process.exit(1);
        }
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
          return writeJsonTemplate(source, templateString, base, commander.validate != null);
        }
      }));
    }
    return _results;
  };

  validateArgs = function() {
    if (commander.args.length === 0) {
      console.error("You need to specify a coffin template to act on.");
      return false;
    }
    if (commander.validate != null) {
      if (commander.print != null) {
        console.error("I can't validate if you're just printing to the console.");
        return false;
      }
      if (!process.env.AWS_CLOUDFORMATION_HOME && !(commander.cloudFormationHome != null)) {
        console.error("Either an AWS_CLOUDFORMATION_HOME environment variable or a --cloudFormationHome switch is required to validate.");
        return false;
      }
    }
    return true;
  };

  writeJsonTemplate = function(source, json, base, validate) {
    var filename, templatePath, write;
    filename = path.basename(source, path.extname(source)) + '.template';
    templatePath = path.join(base, filename);
    write = function() {
      if (json.length <= 0) json = ' ';
      return fs.writeFile(templatePath, json, function(err) {
        var cfnPath, validateCommand;
        if (err) console.err(err.message);
        console.log("\u26B0 " + templatePath);
        if (validate) {
          cfnPath = path.normalize("" + process.env.AWS_CLOUDFORMATION_HOME + "/bin");
          validateCommand = "cfn-validate-template --template-file " + templatePath;
          return exec("" + cfnPath + "/" + validateCommand, function(err) {
            if (!err) return console.log("\u26B0 " + templatePath + " is valid");
          });
        }
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
