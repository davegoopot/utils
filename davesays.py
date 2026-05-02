# /// script
# dependencies = ["cowsay"]
# ///

import cowsay
import sys
from datetime import datetime

message = " ".join(sys.argv[1:])
timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
print(cowsay.get_output_string("cow", f"Dave says ({timestamp}): {message}"))
