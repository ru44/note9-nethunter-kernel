import sys
from androguard.misc import AnalyzeAPK
a, d, dx = AnalyzeAPK(sys.argv[1])
want_class = sys.argv[2]
want_meths = sys.argv[3].split(",") if len(sys.argv) > 3 else None
for dex in d:
    for cls in dex.get_classes():
        cn = cls.get_name()
        if want_class not in cn:
            continue
        print("CLASS", cn, "  SUPER:", cls.get_superclassname())
        for m in cls.get_methods():
            if m.get_code() is None:
                continue
            if want_meths and m.get_name() not in want_meths:
                continue
            print("\n---- %s %s %s ----" % (cn, m.get_name(), m.get_descriptor()))
            for ins in m.get_instructions():
                print("   %-20s %s" % (ins.get_name(), ins.get_output()))
