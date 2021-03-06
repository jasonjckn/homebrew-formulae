class RRequirement < Requirement
  fatal true

  satisfy(:build_env => false) {
    ENV["GRAALVM_HOME"] =  Utils.popen_read(
      "/usr/libexec/java_home -V 2>&1 |
         grep GraalVM |
         awk -F\\\" '{ print $3; }' |
         head -n 1 |
         xargs echo -n")
    which(Pathname.new(ENV["GRAALVM_HOME"])/"bin/native-image")

  }

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

  uses_from_macos "ruby" => :build
  depends_on "clojure/tools/clojure" => :build
  depends_on RRequirement

  def install
    system "clojure", "-A:native-image"
    system "mkdir", prefix/"bin"
    system "cp", "core", prefix/"bin/j2edn"
  end

end
