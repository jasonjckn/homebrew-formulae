class Testa < Formula
  desc "The Clojure Programming Language"
  homepage "https://clojure.org"
  head "https://github.com/jasonjckn/j2edn.git"

  bottle :unneeded

  uses_from_macos "ruby" => :build
  depends_on "rlwrap"
  depends_on "clojure/tools/clojure" => :build
  #depends_on cask: "graalvm/tap/graalvm-ce-java11"


  def install

    ENV["JAVA_HOME"] =  "/Library/Java/JavaVirtualMachines/graalvm-ce-java11-20.0.0/Contents/Home"
    system "clojure", "-A:native-image"
  end



  test do
    ENV["TERM"] = "xterm"
    system("#{bin}/clj -e nil")
    %w[clojure clj].each do |clj|
      assert_equal "2", shell_output("#{bin}/#{clj} -e \"(+ 1 1)\"").strip
    end
  end
end
