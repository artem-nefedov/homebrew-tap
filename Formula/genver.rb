class Genver < Formula
  desc "GenVer - Git SemVer generator"
  homepage "https://github.com/artem-nefedov/genver"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/artem-nefedov/genver/releases/download/v0.3.0/genver_0.3.0_macos_arm64.tar.gz"
      sha256 "aa9080cd81f0459754f3969cf2a6314cc9890d0429c421baf9bd87cc8e53d2b5"
    else
      url "https://github.com/artem-nefedov/genver/releases/download/v0.3.0/genver_0.3.0_macos_amd64.tar.gz"
      sha256 "2aa689a0711eb35481478b1e9d3c9ea88b3cb7ad111185ffd2160257d829ee7e"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/artem-nefedov/genver/releases/download/v0.3.0/genver_0.3.0_linux_arm64.tar.gz"
      sha256 "0e9043ef71617344f7ece785816a59e3172f4ee5f7e959aa5792d879f8ffde90"
    else
      url "https://github.com/artem-nefedov/genver/releases/download/v0.3.0/genver_0.3.0_linux_amd64.tar.gz"
      sha256 "772c6cc864d76bbcade0d1cd8c941d58aa41678dd8d30db949ac069c04c41815"
    end
  end

  def install
    bin.install "genver"

    # genver is a flat, flags-only CLI built on Go's stdlib `flag` package and has
    # no `completion` subcommand, so ship hand-written completions for its flags.
    (buildpath/"genver.bash").write <<~BASH
      _genver() {
          local cur prev opts
          COMPREPLY=()
          cur="${COMP_WORDS[COMP_CWORD]}"
          prev="${COMP_WORDS[COMP_CWORD-1]}"

          opts="--help --version --format --tag-format --write-to --allow-nonhermetic --branch --tag-main --push-tag-to --debug"

          case "${prev}" in
              --branch|--push-tag-to|--format|--tag-format|--format-for)
                  # Free-form values; no known completion set.
                  return 0
                  ;;
              --write-to)
                  compopt -o default 2>/dev/null
                  COMPREPLY=()
                  return 0
                  ;;
          esac

          COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
          return 0
      }

      complete -F _genver genver
    BASH

    (buildpath/"_genver").write <<~ZSH
      #compdef genver

      _genver() {
          local -a opts
          opts=(
              '--help[Show help and exit]'
              '--version[Show genver'\\''s own version and exit]'
              '--format[Render the version through a Go template]:template:'
              '--tag-format[Like --format, but only shapes the tag from --tag-main]:template:'
              '--write-to[Also write the output to the file(s) named by this template]:template:'
              '--format-for[Conditional prefix-based format rule (repeatable)]:prefix:'
              '--allow-nonhermetic[Expose all Sprig template functions, including non-repeatable ones]'
              '--branch[Branch name to compute for]:branch:'
              '--tag-main[Tag HEAD on main with the computed version]'
              '--push-tag-to[Push only the computed tag to the given remote name or URL]:remote:'
              '--debug[Trace calculation steps to stderr]'
          )

          _arguments -s $opts
      }

      _genver "$@"
    ZSH

    (buildpath/"genver.fish").write <<~FISH
      # genver has no subcommands; it is a flat, flags-only CLI.
      complete -c genver -f

      complete -c genver -l help              -d "Show help and exit"
      complete -c genver -l version           -d "Show genver's own version and exit"
      complete -c genver -l format            -r -d "Render the version through a Go template"
      complete -c genver -l tag-format        -r -d "Like --format, but only shapes the tag from --tag-main"
      complete -c genver -l write-to          -r -d "Also write output to file(s) named by this template"
      complete -c genver -l format-for        -r -d "Conditional prefix-based format rule (repeatable)"
      complete -c genver -l allow-nonhermetic -d "Expose all Sprig template functions, including non-repeatable ones"
      complete -c genver -l branch            -r -d "Branch name to compute for"
      complete -c genver -l tag-main          -d "Tag HEAD on main with the computed version"
      complete -c genver -l push-tag-to       -r -d "Push only the computed tag to the given remote name or URL"
      complete -c genver -l debug             -d "Trace calculation steps to stderr"
    FISH

    bash_completion.install "genver.bash" => "genver"
    zsh_completion.install "_genver"
    fish_completion.install "genver.fish"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/genver --version")
  end
end
