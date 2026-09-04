{ fetchurl, runCommand }:

runCommand "uwe5622-firmware" { } ''
  install -Dm644 ${
    fetchurl {
      url = "https://raw.githubusercontent.com/armbian/firmware/master/uwe5622/wcnmodem.bin";
      hash = "sha256-EZuHzjCHVzSmdGL3KT+4/oWs8ycP6LeMl4riS+dxWoA=";
    }
  } $out/lib/firmware/uwe5622/wcnmodem.bin
  install -Dm644 ${
    fetchurl {
      url = "https://raw.githubusercontent.com/armbian/firmware/master/uwe5622/wifi_2355b001_1ant.ini";
      hash = "sha256-HzxA7CRajQuZrRwjcGWX1t1QCKuAzvt7zBlW78TpOPc=";
    }
  } $out/lib/firmware/wifi_2355b001_1ant.ini
''
