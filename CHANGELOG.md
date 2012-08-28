0.2.0 8-22-2012
---------------------------
- *breaking change* Prefacing @Region or @StackName with 'Ref:' is no longer required
- New 'decompile' command
 > decompile [cfn-template]
 > Convert the given cloud formation template to coffin (or as best as we can). It will output a file of the same name with ".coffin" extension.
- Added relative reference to coffin library so it can be used without having it install globally
