class RRequirement < Requirement
  fatal true

  satisfy(:build_env => false) { which("native-image2") }

  def message; <<~EOS
    GraalVM + native-image is required; install it via one of:
      brew cask install graalvm/tap/graalvm-ce-java11
      $GRAALVM_HOME/bin/gu install native-image
    EOS
  end
end

class J2edn < Formula
  head "https://github.com/jasonjckn/j2edn.git"
  bottle :unneeded

  ENV["GRAALVM_HOME"] =  "/Library/Java/JavaVirtualMachines/graalvm-ce-java11-20.0.0/Contents/Home"
  ENV.prepend_path "PATH", Pathname.new(ENV["GRAALVM_HOME"])/"bin/"

  uses_from_macos "ruby" => :build
  depends_on "clojure/tools/clojure" => :build
  depends_on RRequirement

  def install
    system "sudo", "-u", "jason", "gu", "install", "-f", "native-image"
    system "clojure", "-A:native-image"
    system "mkdir", prefix/"bin"
    system "cp", "core", prefix/"bin/j2edn"
  end

  test do
    ENV["TERM"] = "xterm"
    system("#{bin}/clj -e nil")
    %w[clojure clj].each do |clj|
      assert_equal "2", shell_output("#{bin}/#{clj} -e \"(+ 1 1)\"").strip
    end
  end
end
