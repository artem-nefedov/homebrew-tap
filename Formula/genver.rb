class Genver < Formula
  desc "GenVer - Git SemVer generator"
  homepage "https://github.com/artem-nefedov/genver"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/artem-nefedov/genver/releases/download/v0.1.0/genver_0.1.0_macos_arm64.tar.gz"
      sha256 "1e5612590d7c19fe3e8f574b774c228ab14b1c995267c51846ef2a5b9f3331b1"
    else
      url "https://github.com/artem-nefedov/genver/releases/download/v0.1.0/genver_0.1.0_macos_amd64.tar.gz"
      sha256 "5a7279a165e68341c7179da4b97a0de7690705a25a3dc5fbe165f9900dc3c318"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/artem-nefedov/genver/releases/download/v0.1.0/genver_0.1.0_linux_arm64.tar.gz"
      sha256 "86902911f7eb0b3d3920609712347a2173b669847f3263c242323457adb5f287"
    else
      url "https://github.com/artem-nefedov/genver/releases/download/v0.1.0/genver_0.1.0_linux_amd64.tar.gz"
      sha256 "b5a51ed96e73993ff10414ca0dcccd24f0a3b3bf0735278298b577e878ea6f46"
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
              --branch|--push-tag-to|--format|--tag-format)
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
