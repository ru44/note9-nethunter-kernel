import sys
from androguard.misc import AnalyzeAPK

apk = sys.argv[1]
a, d, dx = AnalyzeAPK(apk)

# classes we care about (the popup + its helpers + the receiver that builds the intent)
TARGETS = [
    "CmasDialogRegionalActivity",
    "CmasDialogGlobalActivity",
    "CmasBaseActivity",
    "CmasDialogUtil",
    "CbCmasReceiver",
    "CmasData",
]

def methods(dexes):
    for dex in dexes:
        for cls in dex.get_classes():
            cn = cls.get_name()
            if not any(t in cn for t in TARGETS):
                continue
            for m in cls.get_methods():
                yield cn, m

for cn, m in methods(d):
    if m.get_code() is None:
        continue
    mn = m.get_name()
    print("\n==== %s -> %s ====" % (cn, mn))
    try:
        for ins in m.get_instructions():
            out = ins.get_output()
            nm = ins.get_name()
            # keep the signal-bearing lines: method calls, string constants, static field access
            if (nm.startswith("invoke")
                    or nm.startswith("const-string")
                    or nm.startswith("sget")
                    or nm.startswith("sput")
                    or "Extra" in out
                    or "Vector" in out):
                print("   %-22s %s" % (nm, out))
    except Exception as e:
        print("   <err %s>" % e)
