# Copyright (c) 2024 liudepei. All Rights Reserved.
# create at 2024/06/09 20:17:00 星期日

import os
import sys

if __name__ == "__main__":
    if len(sys.argv) < 2:
        os._exit(1)
    if not os.path.exists(sys.argv[1]):
        os._exit(2)
    for dir, dirs, files in os.walk(sys.argv[1]):
        for file in files:
            if file.split('.')[-1].lower() == 'md':
                print(os.path.join(dir, file))
