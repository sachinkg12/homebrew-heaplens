class Heaplens < Formula
  desc "Local Java heap analysis with a CLI and browser UI"
  homepage "https://github.com/sachinkg12/heaplens"
  url "https://github.com/sachinkg12/heaplens/releases/download/cli-v0.1.1/heaplens-cli-0.1.1-darwin-arm64.tar.gz"
  version "0.1.1"
  sha256 "92daf8f8f4903d441c321c2bbeb5f1dd1e09a9a4a95196df18bddb82c6c557b5"
  license "Apache-2.0"

  depends_on :macos
  depends_on arch: :arm64
  depends_on "node"

  def install
    libexec.install Dir["*"]
    (bin/"heaplens").write <<~SH
      #!/bin/sh
      exec "#{Formula["node"].opt_bin}/node" "#{libexec}/bin/heaplens.cjs" "$@"
    SH
    (bin/"heaplens").chmod 0755
  end

  def caveats
    <<~EOS
      Telemetry is on by default. Disable with --telemetry off or DO_NOT_TRACK=1.
      AI features require a provider configuration and approval to send source.
    EOS
  end

  test do
    require "json"
    assert_match "heaplens", shell_output("#{bin}/heaplens --help")
    assert_match "0.1.1", shell_output("#{bin}/heaplens --version")
    header = "JAVA PROFILE 1.0.2\0" + [8].pack("N") + [0].pack("Q>")
    array = [0xff].pack("C") + [512].pack("Q>") + [0x23].pack("C") +
      [512].pack("Q>") + [0, 9].pack("N2") + [8].pack("C") + ("x" * 9)
    heap = header + [0x1c, 0, array.bytesize].pack("CNN") + array + [0x2c, 0, 0].pack("CNN")
    (testpath/"synthetic.hprof").binwrite heap
    ENV["DO_NOT_TRACK"] = "1"
    result = JSON.parse(shell_output("#{bin}/heaplens analyze #{testpath}/synthetic.hprof --quiet --format json"))
    assert_equal "completed", result.fetch("status")
    assert_equal 1, result.fetch("data").fetch("summary").fetch("total_arrays")
  end
end
