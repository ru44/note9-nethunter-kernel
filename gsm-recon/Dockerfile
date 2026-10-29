# gr-gsm needs GNU Radio 3.8. Ubuntu 26.04 ships GNU Radio 3.10 + Python 3.14
# and has NO gr-gsm package; building gr-gsm against 3.10 is unreliable.
#
# Ubuntu 20.04 (focal) ships GNU Radio *3.8* + gr-osmosdr, but also has no
# gr-gsm package — so we build gr-gsm (velichkov's maintained fork) from source
# against 3.8 inside this container, and keep the 26.04 host completely clean.
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# GNU Radio 3.8 stack + gr-gsm build dependencies.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      gnuradio gnuradio-dev gr-osmosdr rtl-sdr \
      cmake make g++ git pkg-config \
      libboost-all-dev libcppunit-dev liblog4cpp5-dev swig \
      libosmocore-dev liborc-0.4-dev \
      python3-numpy python3-scipy python3-mako python3-six python3-yaml \
      ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Build gr-gsm against the system GNU Radio 3.8 and install alongside it
# (prefix /usr) so the grgsm_* tools and the python module are on the default
# paths — no PYTHONPATH juggling needed.
RUN git clone --depth 1 https://github.com/velichkov/gr-gsm.git /tmp/gr-gsm \
 && cmake -S /tmp/gr-gsm -B /tmp/gr-gsm/build -DCMAKE_INSTALL_PREFIX=/usr \
 && cmake --build /tmp/gr-gsm/build -j"$(nproc)" \
 && cmake --install /tmp/gr-gsm/build \
 && ldconfig \
 && rm -rf /tmp/gr-gsm

# grgsm_livemon_headless publishes every decoded frame as a GSMTAP packet to
# 127.0.0.1:4729. Run this container with --net=host so those packets land on
# the HOST loopback, where Wireshark (iface: lo, filter: gsmtap) reads them.
ENTRYPOINT []
CMD ["bash"]
