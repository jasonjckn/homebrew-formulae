class Testa < Formula
  desc "The Clojure Programming Language"
  homepage "https://clojure.org"
  head "https://github.com/taylorwood/clojurl.git"

  bottle :unneeded

  depends_on "rlwrap"
  depends_on "clojure/tools/clojure"
  depends_on cask: "graalvm/tap/graalvm-ce-java11"

  uses_from_macos "ruby" => :build

  def install
    system "echo hi", prefix
    system "ls .", prefix
  end

  test do
    ENV["TERM"] = "xterm"
    system("#{bin}/clj -e nil")
    %w[clojure clj].each do |clj|
      assert_equal "2", shell_output("#{bin}/#{clj} -e \"(+ 1 1)\"").strip
    end
  end
end
