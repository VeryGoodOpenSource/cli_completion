# 0.4.0

- docs: update readme with a troubleshooting section ([#63](https://github.com/VeryGoodOpenSource/cli_completion/pull/63))
- feat: included `CompletionConfiguration` class ([#71](https://github.com/VeryGoodOpenSource/cli_completion/pull/71))
- feat: include uninstallation logic ([#70](https://github.com/VeryGoodOpenSource/cli_completion/pull/70))
- feat: include `UninstallCompletionFilesCommand` ([#72](https://github.com/VeryGoodOpenSource/cli_completion/pull/72))
- feat: avoid auto-installing manually uninstalled commands ([#73](https://github.com/VeryGoodOpenSource/cli_completion/pull/73))
- feat: avoid auto-installing when already installed ([#74](https://github.com/VeryGoodOpenSource/cli_completion/pull/74))

# [0.3.0](https://github.com/VeryGoodOpenSource/cli_completion/compare/v0.2.0...v0.3.0) (2023-02-27)

### Bug Fixes

- completion installation ([#53](https://github.com/VeryGoodOpenSource/cli_completion/issues/53)) ([bb277bb](https://github.com/VeryGoodOpenSource/cli_completion/commit/bb277bbf802f2d397055c753377373022d24818a))

### Features

- store completions in `$XDG_CONFIG_HOME` instead of `$HOME` ([#50](https://github.com/VeryGoodOpenSource/cli_completion/issues/50)) ([d2d7459](https://github.com/VeryGoodOpenSource/cli_completion/commit/d2d74597fc144961c784f4285de5f68122942e05))

# [0.2.0](https://github.com/VeryGoodOpenSource/cli_completion/compare/v0.1.0+1...v0.2.0) (2023-01-13)

### Features

- restrict non multi options ([#44](https://github.com/VeryGoodOpenSource/cli_completion/issues/44)) ([32dfc23](https://github.com/VeryGoodOpenSource/cli_completion/commit/32dfc23dedfa48cad2dc8fc9db5f7136fed46243))
- suggest negatable flags ([#45](https://github.com/VeryGoodOpenSource/cli_completion/issues/45)) ([8e0049a](https://github.com/VeryGoodOpenSource/cli_completion/commit/8e0049af3801ed6bedbe52851fc1262c112d6a91))
- Tell the user to source the config file when installation is done ([#41](https://github.com/VeryGoodOpenSource/cli_completion/issues/41)) ([53d1f08](https://github.com/VeryGoodOpenSource/cli_completion/commit/53d1f08fe0aea38d8fa22964db1806046f1adcef))

# [0.1.0+1](https://github.com/VeryGoodOpenSource/cli_completion/compare/v0.1.0...v0.1.0+1) (2022-12-09)

# [0.1.0](https://github.com/VeryGoodOpenSource/cli_completion/compare/d7cdfd51b923d2d5720864b228678749f3010fb8...v0.1.0) (2022-12-08)

### Bug Fixes

- add system shell identification by heuristics ([#31](https://github.com/VeryGoodOpenSource/cli_completion/issues/31)) ([d30f59e](https://github.com/VeryGoodOpenSource/cli_completion/commit/d30f59e677bfd3a8a9f307ce33123e9a96b25644))

### Features

- add example app ([#9](https://github.com/VeryGoodOpenSource/cli_completion/issues/9)) ([452d1dd](https://github.com/VeryGoodOpenSource/cli_completion/commit/452d1dd0ec7e17711e4586d5763b0d498dfc8505))
- add idea run config ([#20](https://github.com/VeryGoodOpenSource/cli_completion/issues/20)) ([859c7f6](https://github.com/VeryGoodOpenSource/cli_completion/commit/859c7f66e43d962558ee412212b2acd6ed28b71e))
- add install triggers ([#10](https://github.com/VeryGoodOpenSource/cli_completion/issues/10)) ([cf0fe94](https://github.com/VeryGoodOpenSource/cli_completion/commit/cf0fe94cf648825cce063c5068bc39586f3b9e88))
- add installation process for bash ([#8](https://github.com/VeryGoodOpenSource/cli_completion/issues/8)) ([af74cec](https://github.com/VeryGoodOpenSource/cli_completion/commit/af74cec6dbbad75858adf819e599c2c9ff4c2f42))
- add installation process for zsh ([#7](https://github.com/VeryGoodOpenSource/cli_completion/issues/7)) ([d7cdfd5](https://github.com/VeryGoodOpenSource/cli_completion/commit/d7cdfd51b923d2d5720864b228678749f3010fb8))
- add integrated tests ([#19](https://github.com/VeryGoodOpenSource/cli_completion/issues/19)) ([615ef3d](https://github.com/VeryGoodOpenSource/cli_completion/commit/615ef3dbda6cfe4c61236ee61e3e49657b5e3c6e))
- add optional auto-install ([#29](https://github.com/VeryGoodOpenSource/cli_completion/issues/29)) ([e8585d6](https://github.com/VeryGoodOpenSource/cli_completion/commit/e8585d6e4d110d038dcffd82b9cf40d097e25785))
- handle completion request ([#17](https://github.com/VeryGoodOpenSource/cli_completion/issues/17)) ([aada678](https://github.com/VeryGoodOpenSource/cli_completion/commit/aada678e5cd009e304ab1712bfa0e45d9e5d1ce5))
- list files when there is no completion on zsh ([#21](https://github.com/VeryGoodOpenSource/cli_completion/issues/21)) ([ca273fc](https://github.com/VeryGoodOpenSource/cli_completion/commit/ca273fc1d3b8cab7c91e55e50f5b9bd4db4b2a96))
- suggest options, flags and option values ([#24](https://github.com/VeryGoodOpenSource/cli_completion/issues/24)) ([7677ab6](https://github.com/VeryGoodOpenSource/cli_completion/commit/7677ab6497a97c972ce7ce89d4af7731e296aea3))
- suggest sub commands ([#22](https://github.com/VeryGoodOpenSource/cli_completion/issues/22)) ([ea3f5db](https://github.com/VeryGoodOpenSource/cli_completion/commit/ea3f5dbf9c734e33a04a719687552055ec790f4b))
