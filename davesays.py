# /// script
# dependencies = ["cowsay"]
# ///

import cowsay
import sys

message = " ".join(sys.argv[1:])
print(cowsay.get_output_string("cow", f"Dave says: {message}"))
