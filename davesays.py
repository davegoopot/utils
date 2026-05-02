# /// script
# dependencies = ["cowsay"]
# ///

import cowsay
import sys
from datetime import datetime, timezone

message = " ".join(sys.argv[1:])
timestamp = datetime.now(timezone.utc).astimezone().strftime("%Y-%m-%d %H:%M:%S %Z")
print(cowsay.get_output_string("cow", f"Dave says ({timestamp}): {message}"))
