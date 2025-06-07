import csv
import urllib.request
from pathlib import Path

URL = "https://raw.githubusercontent.com/jpatokal/openflights/master/data/airports.dat"
OUTPUT = Path(__file__).resolve().parents[1] / "data" / "airports.csv"


def main() -> None:
    with urllib.request.urlopen(URL) as resp:
        lines = resp.read().decode("utf-8").splitlines()
    reader = csv.reader(lines)

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with OUTPUT.open("w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["iata_code", "airport_name"])
        count = 0
        for row in reader:
            iata = row[4]
            name = row[1]
            if iata and iata != "\\N":
                writer.writerow([iata, name])
                count += 1
    print(f"Wrote {count} rows to {OUTPUT}")


if __name__ == "__main__":
    main()
