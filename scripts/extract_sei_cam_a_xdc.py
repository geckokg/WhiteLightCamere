from pathlib import Path
import re


SOURCE_XDC = Path(r"D:/ZYNQ/lasercom/lasercom_top/Sei_Pin.xdc")
OUTPUT_XDC = Path("constraints/sei_pin_cam_a.generated.xdc")

KEEP_PORTS = {
    "sys_clk_p",
    "sys_clk_n",
    "i_lvds_clk_p",
    "i_lvds_clk_n",
    "i_lvds_sync_p",
    "i_lvds_sync_n",
    "i_lvds_data0_p",
    "i_lvds_data0_n",
    "i_lvds_data1_p",
    "i_lvds_data1_n",
    "i_lvds_data2_p",
    "i_lvds_data2_n",
    "i_lvds_data3_p",
    "i_lvds_data3_n",
    "spi_sck",
    "spi_ss_n",
    "spi_mosi",
    "spi_miso",
    "camera_reset_n",
    "camera_vdd_18_en",
    "camera_vdd_33_en",
    "camera_lvds_clk",
    "trigger_0",
}


def is_keepable(line: str) -> bool:
    stripped = line.strip()
    if not stripped or stripped.startswith("#"):
        return False
    if "get_nets" in stripped:
        return False
    matches = re.findall(r"get_ports\s+(?:\{([^}]+)\}|([^\]\s]+))", stripped)
    ports = [left or right for left, right in matches]
    return bool(ports) and all(port in KEEP_PORTS for port in ports)


def main() -> None:
    if not SOURCE_XDC.exists():
        raise SystemExit(f"source XDC not found: {SOURCE_XDC}")

    lines = SOURCE_XDC.read_text(encoding="utf-8", errors="ignore").splitlines()
    kept = [line.rstrip() for line in lines if is_keepable(line)]
    header = [
        "## Generated from D:/ZYNQ/lasercom/lasercom_top/Sei_Pin.xdc",
        "## Scope: sys_clk and CAM A pins only.",
        "## Old hierarchical get_nets constraints and unrelated SDI/UART/CAM B pins are intentionally omitted.",
        "",
    ]
    OUTPUT_XDC.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_XDC.write_text("\n".join(header + kept) + "\n", encoding="ascii")
    print(f"Wrote {OUTPUT_XDC} from {SOURCE_XDC}")


if __name__ == "__main__":
    main()
