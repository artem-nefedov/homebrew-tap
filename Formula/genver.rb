class Genver < Formula
  desc "GenVer - Git SemVer generator"
  homepage "https://github.com/artem-nefedov/genver"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/artem-nefedov/genver/releases/download/v0.5.1/genver_0.5.1_macos_arm64.tar.gz"
      sha256 "9e78f52b14e15ac94ed5f4b73223f52a47f8dfeb1b772634ac6f146576706384"
    else
      url "https://github.com/artem-nefedov/genver/releases/download/v0.5.1/genver_0.5.1_macos_amd64.tar.gz"
      sha256 "fd1c266316f750d4b08f1b4aba0c439cbe3cbd0d74e66074fc91726511542f74"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/artem-nefedov/genver/releases/download/v0.5.1/genver_0.5.1_linux_arm64.tar.gz"
      sha256 "344be709eb45bfeb0166dd0a3e09ce1328b053a8348c2040ceae50496a27f095"
    else
      url "https://github.com/artem-nefedov/genver/releases/download/v0.5.1/genver_0.5.1_linux_amd64.tar.gz"
      sha256 "98c5c5ff335f70b66ba5639c8da590bb33c834caea90a57657af0572566f6194"
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

          opts="--help --version --format --format-tag --write-to --format-for --allow-nonhermetic --branch --tag-main --push-tag-to --debug"

          case "${prev}" in
              --branch|--push-tag-to|--format|--format-tag|--format-for)
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
              '--format-tag[Like --format, but only shapes the tag from --tag-main]:template:'
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
      complete -c genver -l format-tag        -r -d "Like --format, but only shapes the tag from --tag-main"
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
