(function() {
  var CoffeeScript, commander, compileCommand, compileTemplate, exec, fs, path, printCommand, spawn, stackCommand, validateArgs, validateCommand, validateTemplate, writeJsonTemplate, _ref;
  var _this = this;

  fs = require('fs');

  path = require('path');

  commander = require('commander');

  CoffeeScript = require('coffee-script');

  _ref = require('child_process'), spawn = _ref.spawn, exec = _ref.exec;

  validateArgs = function() {
    var valid;
    valid = true;
    if (commander.args.length === 0) {
      console.error("You need to specify a coffin template to act on.");
      valid = false;
    }
    if ((commander.validate != null) || (commander.createStack != null) || (commander.updateStack != null)) {
      if (commander.print != null) {
        console.error("I can't run that command if you're just printing to the console.");
        valid = false;
      }
      if (!process.env.AWS_CLOUDFORMATION_HOME && !(commander.cloudFormationHome != null)) {
        console.error("Either an AWS_CLOUDFORMATION_HOME environment variable or a --cfnHome switch is required.");
        valid = false;
      }
    }
    if (!valid) {
      process.stdout.write(commander.helpInformation());
      return process.exit(0);
    }
  };

  compileTemplate = function(source, callback) {
    var pre;
    pre = "require('coffin') ->\n";
    return fs.readFile(source, function(err, code) {
      var compiled, line, tabbedLines, template, templateString;
      if (err) {
        console.error("" + source + " not found");
        process.exit(1);
      }
      tabbedLines = (function() {
        var _i, _len, _ref2, _results;
        _ref2 = code.toString().split('\n');
        _results = [];
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          line = _ref2[_i];
          _results.push('  ' + line);
        }
        return _results;
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
      return typeof callback === "function" ? callback(templateString) : void 0;
    });
  };

  writeJsonTemplate = function(source, json, callback) {
    var base, filename, templatePath, write;
    base = commander.output || path.dirname(source);
    filename = path.basename(source, path.extname(source)) + '.template';
    templatePath = path.join(base, filename);
    write = function() {
      if (json.length <= 0) json = ' ';
      return fs.writeFile(templatePath, json, function(err) {
        if (err) console.err(err.message);
        console.log("\u26B0 " + templatePath);
        return typeof callback === "function" ? callback(templatePath) : void 0;
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

  validateTemplate = function(templatePath, callback) {
    var cfnPath, validateExec;
    cfnPath = path.normalize("" + process.env.AWS_CLOUDFORMATION_HOME + "/bin");
    validateExec = "cfn-validate-template --template-file " + templatePath;
    return exec("" + cfnPath + "/" + validateExec, function(err) {
      if (!err) console.log("\u26B0 " + templatePath + " is valid");
      return typeof callback === "function" ? callback() : void 0;
    });
  };

  commander.version('0.0.2');

  commander.usage('[options] <coffin template>');

  commander.option('-o, --output [dir]', 'Directory to output compiled file(s) to');

  commander.option('-p, --pretty', 'Add spaces and stuff to the resulting json to make it a little prettier');

  commander.option('--cfn-home [dir]', 'The home of your AWS Cloudformation tools. Defaults to your AWS_CLOUDFORMATION_HOME environment variable.');

  printCommand = commander.command('print [template]');

  printCommand.description('Print the compiled template.');

  printCommand.action(function(template) {
    validateArgs();
    return compileTemplate(template, function(compiled) {
      return console.log(compiled);
    });
  });

  validateCommand = commander.command('validate [template]');

  validateCommand.description('Validate the compiled template. Either an AWS_CLOUDFORMATION_HOME environment variable or a --cloudFormationHome switch is required.');

  validateCommand.action(function(template) {
    validateArgs();
    return compileTemplate(template, function(compiled) {
      return writeJsonTemplate(template, compiled, function(fullCompiledPath) {
        return validateTemplate(fullCompiledPath);
      });
    });
  });

  stackCommand = commander.command('stack [name] [template]');

  stackCommand.description('Create or update the named stack using the compiled template.');

  stackCommand.action(function(name, template) {
    validateArgs();
    return console.log("todo: check to see if " + name + " stack exists, either create or update based on " + template);
  });

  compileCommand = commander.command('compile [template]');

  compileCommand.description('Compile and write the template. The output file will have the same name as the coffin template plus a shiny new ".template" extension.');

  compileCommand.action(function(template) {
    validateArgs();
    return compileTemplate(template, function(compiled) {
      return writeJsonTemplate(template, compiled);
    });
  });

  module.exports.run = function() {
    return commander.parse(process.argv);
  };

}).call(this);
