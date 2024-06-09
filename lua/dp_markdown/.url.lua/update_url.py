# Copyright (c) 2024 liudepei. All Rights Reserved.
# create at 2024/06/09 20:17:00 星期日

import os
import re
import sys

patt = re.compile(rb"(`([^:]+):([^`]+?)`)")

Files = {}
FilesShort = {}

if __name__ == "__main__":
    if len(sys.argv) < 2:
        os._exit(1)
    root = sys.argv[1]
    dirname = os.path.dirname(root).encode("utf-8")
    print(root)
    if not os.path.exists(root):
        os._exit(2)
    for dir, dirs, files in os.walk(root):
        for file in files:
            if file.split(".")[-1].lower() != "md":
                continue
            file = os.path.join(dir, file)
            with open(file, "rb") as f:
                lines = f.readlines()
            res = 0
            for line in lines:
                res = re.findall(patt, line)
                if res:
                    break
            if not res:
                continue
            new_lines = []
            allowed = 0
            printed = 0
            for line in lines:
                new_line = line
                res = re.findall(patt, line)
                if res:
                    for r in res:
                        d = os.path.join(dirname, r[1])
                        if not os.path.exists(d):
                            continue
                        rname = r[2]
                        f = os.path.join(d, rname)
                        if not os.path.exists(f):
                            if d not in Files:
                                Files[d] = []
                                FilesShort[d] = []
                                for _d, _, _fs in os.walk(d):
                                    for _f in _fs:
                                        # if _f.split(b".")[-1].lower() != b"md":
                                        #     continue
                                        Files[d].append(os.path.join(_d, _f).lower())
                                        FilesShort[d].append(_f.split(b"/")[-1].lower())
                            fname = rname.split(b"/")[-1].lower()
                            c =  FilesShort[d].count(fname)
                            if printed == 0:
                                printed = 1
                                print(file)
                            print(c, '  ', rname.decode('utf-8'))
                            if (
                                FilesShort[d].count(fname) == 1
                            ):  # 只处理只找到一个相同文件名的情况,不存在或存在多个相同文件名的不处理
                                new_rname = os.path.relpath(Files[d][FilesShort[d].index(fname)], d).replace(b"\\", b"/")
                                new_line = new_line.replace( rname, new_rname)
                                allowed = 1
                                _t = ''
                                for _ in range(len(str(c))):
                                    _t += ' '
                                print(_t, '->', new_rname.decode('utf-8'))
                new_lines.append(new_line)
            if allowed:
                with open(file, "wb") as f:
                    f.writelines(new_lines)
