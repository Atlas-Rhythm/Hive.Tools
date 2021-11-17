# Hive.Tools

This repo contains build tooling for [Hive](https://github.com/Atlas-Rhythm/Hive) and [HiveCorePlugins](https://github.com/Atlas-Rhythm/Hive). It is used as a submodule,
typically at `/tools/`. The containing repository then imports `_Build.props` in its
`Directory.Build.props` and `_Build.targets` in its `Directory.Build.targets`.