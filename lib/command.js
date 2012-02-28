(function() {
  var CoffeeScript, buildCfnPath, checkChar, coffinChar, colors, commander, compileCommand, compileTemplate, createStack, crossChar, exec, fs, generateOutputFileName, generateTempFileName, path, pretty, printCommand, showHelp, spawn, stackCommand, updateOrCreateStack, validateArgs, validateCommand, validateTemplate, writeJsonTemplate, _ref,
    _this = this,
    __slice = Array.prototype.slice;

  fs = require('fs');

  path = require('path');

  colors = require('colors');

  commander = require('commander');

  CoffeeScript = require('coffee-script');

  _ref = require('child_process'), spawn = _ref.spawn, exec = _ref.exec;

  coffinChar = '\u26B0'.grey;

  checkChar = '\u2713'.green;

  crossChar = '\u2717'.red;

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
      if (!process.env.AWS_CLOUDFORMATION_HOME && !(commander['cfn-home'] != null)) {
        console.error("Either an AWS_CLOUDFORMATION_HOME environment variable or a --cfnHome switch is required.");
        valid = false;
      }
    }
    if (!valid) {
      process.stdout.write(commander.helpInformation());
      return process.exit(0);
    }
  };

  compileTemplate = function(source, params, callback) {
    var pre;
    pre = "require('coffin') ->\n";
    return fs.readFile(source, function(err, code) {
      var compiled, line, tabbedLines, template, templateString, _i, _len, _ref2;
      if (err) {
        console.error("" + source + " not found");
        process.exit(1);
      }
      tabbedLines = [];
      if (!(params != null)) params = [];
      tabbedLines.push("  @ARGV = " + (JSON.stringify(params)));
      _ref2 = code.toString().split('\n');
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        line = _ref2[_i];
        tabbedLines.push('  ' + line);
      }
      tabbedLines.push('  return');
      code = tabbedLines.join('\n');
      code = pre + code;
      compiled = CoffeeScript.compile(code, {
        source: source,
        bare: false
      });
      template = eval(compiled, source);
      templateString = commander.pretty ? JSON.stringify(template, null, 2) : JSON.stringify(template);
      return typeof callback === "function" ? callback(templateString) : void 0;
    });
  };

  writeJsonTemplate = function(json, templatePath, callback) {
    var base, write;
    write = function() {
      if (json.length <= 0) json = ' ';
      return fs.writeFile(templatePath, json, function(err) {
        if (err != null) {
          console.error("failed to write to " + templatePath);
          console.error(err.message);
          process.exit(1);
        }
        return typeof callback === "function" ? callback() : void 0;
      });
    };
    base = path.dirname(templatePath);
    return path.exists(base, function(exists) {
      if (exists) {
        return write();
      } else {
        return exec("mkdir -p " + base, write);
      }
    });
  };

  generateTempFileName = function() {
    var dateStamp, e, name, now, rand, tmpDir;
    e = process.env;
    tmpDir = e.TMPDIR || e.TMP || e.TEMP || '/tmp';
    now = new Date();
    dateStamp = now.getYear();
    dateStamp <<= 4;
    dateStamp |= now.getMonth();
    dateStamp <<= 5;
    dateStamp |= now.getDay();
    rand = (Math.random() * 0x100000000 + 1).toString(36);
    name = "" + (dateStamp.toString(36)) + "-" + (process.pid.toString(36)) + "-" + rand + ".template";
    return path.join(tmpDir, name);
  };

  generateOutputFileName = function(source) {
    var base, filename;
    base = commander.output || path.dirname(source);
    filename = path.basename(source, path.extname(source)) + '.template';
    return path.join(base, filename);
  };

  buildCfnPath = function() {
    var cfnHome;
    cfnHome = commander['cfn-home'] || process.env.AWS_CLOUDFORMATION_HOME;
    return path.normalize(path.join(cfnHome, 'bin'));
  };

  validateTemplate = function(templatePath, callback) {
    var errorText, resultText, validateExec;
    validateExec = spawn(path.join(buildCfnPath(), 'cfn-validate-template'), ['--template-file', templatePath]);
    errorText = '';
    resultText = '';
    validateExec.stderr.on('data', function(data) {
      return errorText += data.toString();
    });
    validateExec.stdout.on('data', function(data) {
      return resultText += data.toString();
    });
    return validateExec.on('exit', function(code) {
      if (code === 0) {
        process.stdout.write("" + checkChar + "\n");
        process.stdout.write(resultText);
      } else {
        process.stdout.write("" + crossChar + "\n");
        process.stderr.write(errorText);
      }
      return typeof callback === "function" ? callback(code) : void 0;
    });
  };

  updateOrCreateStack = function(name, templatePath, callback) {
    var resultText, updateErrorText, updateExec;
    updateExec = spawn("" + (buildCfnPath()) + "/cfn-update-stack", ['--template-file', templatePath, '--stack-name', name]);
    updateErrorText = '';
    resultText = '';
    updateExec.stderr.on('data', function(data) {
      return updateErrorText += data.toString();
    });
    updateExec.stdout.on('data', function(data) {
      return resultText += data.toString();
    });
    return updateExec.on('exit', function(code) {
      if (path.existsSync("" + (buildCfnPath()) + "/cfn-update-stack")) {
        if (code === 0) {
          process.stdout.write("stack '" + name + "' (updated) " + checkChar + "\n");
          process.stdout.write(resultText);
          if (typeof callback === "function") callback(code);
          return;
        }
        if (updateErrorText.match(/^cfn-update-stack:  Malformed input-No updates are to be performed/) != null) {
          process.stdout.write("stack '" + name + "' (no changes)\n");
          process.stdout.write(resultText);
          if (typeof callback === "function") callback(0);
          return;
        }
        if (!(updateErrorText.match(/^cfn-update-stack:  Malformed input-Stack with ID\/name/) != null)) {
          console.error(updateErrorText);
          if (typeof callback === "function") callback(code);
          return;
        }
      }
      return createStack(name, templatePath, callback);
    });
  };

  createStack = function(name, templatePath, callback) {
    var createExec, errorText, resultText;
    createExec = spawn("" + (buildCfnPath()) + "/cfn-create-stack", ['--template-file', templatePath, '--stack-name', name]);
    errorText = '';
    resultText = '';
    createExec.stdout.on('data', function(data) {
      return resultText += data.toString();
    });
    createExec.stderr.on('data', function(data) {
      return errorText += data.toString();
    });
    return createExec.on('exit', function(code) {
      if (code !== 0) {
        if (errorText.match(/^cfn-create-stack:  Malformed input-AlreadyExistsException/) != null) {
          process.stderr.write("stack '" + name + "' already exists " + crossChar + "\n");
          return;
        }
        process.stderr.write(errorText);
        return;
      }
      process.stdout.write("stack '" + name + "' (created) " + checkChar + "\n");
      process.stdout.write(resultText);
      return typeof callback === "function" ? callback(code) : void 0;
    });
  };

  pretty = {
    "switch": '-p, --pretty',
    text: 'Add spaces and newlines to the resulting json to make it a little prettier'
  };

  commander.version(require('./coffin').version);

  commander.usage('[options] <coffin template>');

  commander.option('-o, --output [dir]', 'Directory to output compiled file(s) to');

  commander.option('--cfn-home [dir]', 'The home of your AWS Cloudformation tools. Defaults to your AWS_CLOUDFORMATION_HOME environment variable.');

  commander.option(pretty["switch"], pretty.text);

  printCommand = commander.command('print [template]');

  printCommand.description('Print the compiled template.');

  printCommand.action(function() {
    var params, template;
    template = arguments[0], params = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    validateArgs();
    return compileTemplate(template, params, function(compiled) {
      return console.log(compiled);
    });
  });

  validateCommand = commander.command('validate [template]');

  validateCommand.description('Validate the compiled template. Either an AWS_CLOUDFORMATION_HOME environment variable or a --cfn-home switch is required.');

  validateCommand.action(function() {
    var params, template;
    template = arguments[0], params = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    validateArgs();
    return compileTemplate(template, params, function(compiled) {
      var tempFileName;
      process.stdout.write("" + coffinChar + " " + template + " ");
      tempFileName = generateTempFileName();
      return writeJsonTemplate(compiled, tempFileName, function() {
        return validateTemplate(tempFileName, function(resultCode) {});
      });
    });
  });

  stackCommand = commander.command('stack [name] [template]');

  stackCommand.description('Create or update the named stack using the compiled template. Either an AWS_CLOUDFORMATION_HOME environment variable or a --cfn-home switch is required.');

  stackCommand.action(function() {
    var name, params, template;
    name = arguments[0], template = arguments[1], params = 3 <= arguments.length ? __slice.call(arguments, 2) : [];
    validateArgs();
    return compileTemplate(template, params, function(compiled) {
      var tempFileName;
      tempFileName = generateTempFileName();
      return writeJsonTemplate(compiled, tempFileName, function() {
        process.stdout.write("" + coffinChar + " " + template + " -> ");
        return updateOrCreateStack(name, tempFileName, function(resultCode) {});
      });
    });
  });

  compileCommand = commander.command('compile [template]');

  compileCommand.description('Compile and write the template. The output file will have the same name as the coffin template plus a shiny new ".template" extension.');

  compileCommand.action(function() {
    var params, template;
    template = arguments[0], params = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    validateArgs();
    return compileTemplate(template, params, function(compiled) {
      var fileName;
      process.stdout.write("" + coffinChar + " " + template + " -> ");
      fileName = generateOutputFileName(template);
      return writeJsonTemplate(compiled, fileName, function() {
        return process.stdout.write("" + fileName + "\n");
      });
    });
  });

  showHelp = function() {
    process.stdout.write(commander.helpInformation());
    return process.exit(1);
  };

  commander.command('').action(showHelp);

  commander.command('*').action(showHelp);

  if (process.argv.length <= 2) showHelp();

  module.exports.run = function() {
    return commander.parse(process.argv);
  };

}).call(this);
