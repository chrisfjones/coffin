coffin@0.2.2 - 8-29-2012
---------------------------
- When creating a stack that references an IAM resource, the -c CAPABILITY_IAM flag is added automatically
- Updated reference to existsSync when using node 0.8+ so the error message doesn't appear

coffin@0.2.1 - 8-28-2012
---------------------------
- **breaking change** Changed @InitScript template syntax to use %{} instead of #{} so as not to conflict with coffeescript's native syntax (or shell script variable substitution syntax).

coffin@0.2.0 - 8-22-2012
---------------------------
- **breaking change** Prefacing @Region or @StackName with 'Ref:' is no longer required
- New 'decompile' command
> decompile [cfn-template]
> Convert the given cloud formation template to coffin (or as best as we can). It will output a file of the same name with ".coffin" extension.
- Added relative reference to coffin library so it can be used without having it install globally.
