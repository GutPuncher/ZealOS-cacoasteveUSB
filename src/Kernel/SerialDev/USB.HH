// USB / xHCI / HID constants and structures for ZealOS native input.
// UK/UM defined in KernelA.HH.

#define USB_REQ_GET_DESCRIPTOR	6
#define USB_REQ_SET_ADDRESS		5
#define USB_REQ_SET_CONFIGURATION	9
#define USB_REQ_SET_IDLE		0x0A
#define USB_REQ_SET_INTERFACE	11
#define USB_REQ_SET_PROTOCOL	0x0B

#define USB_DESC_DEVICE		1
#define USB_DESC_CONFIG		2
#define USB_DESC_HID		0x21
#define USB_DESC_REPORT		0x22

#define USB_CLASS_HID		3
#define USB_SUBCLASS_BOOT	1
#define USB_PROTO_KBD		1
#define USB_PROTO_MOUSE		2

// DMA buffers live above EP0 workspace (config descriptors use up to 512 bytes).
#define udma_ms		512
#define udma_kbd		576

#define USB_DIR_IN			0x80
#define USB_DIR_OUT			0x00
#define USB_TYPE_STANDARD	0x00
#define USB_TYPE_CLASS		0x20
#define USB_RECIP_DEVICE	0x00
#define USB_RECIP_INTERFACE	0x01

// xHCI capability / operational register offsets
#define XHCI_CAP_CAPLENGTH	0
#define XHCI_CAP_HCSPARAMS1	0x04
#define XHCI_CAP_HCSPARAMS2	0x08
#define XHCI_CAP_HCCPARAMS1	0x10
#define XHCI_CAP_DBOFF		0x14
#define XHCI_CAP_RTSOFF		0x18

// Runtime register offsets (interrupter 0), from runtime base (RTSOFF)
#define XHCI_RT_MFINDEX		0x00
#define XHCI_RT_IMAN0		0x20
#define XHCI_RT_IMOD0		0x24
#define XHCI_RT_ERSTSZ0		0x28
#define XHCI_RT_ERSTBA0		0x30
#define XHCI_RT_ERDP0		0x38

#define XHCI_OP_USBCMD		0x00
#define XHCI_OP_USBSTS		0x04
#define XHCI_OP_PAGESIZE	0x08
#define XHCI_OP_DNCTRL		0x14
#define XHCI_OP_CRCR		0x18
#define XHCI_OP_DCBAAP		0x30
#define XHCI_OP_CONFIG		0x38
#define XHCI_OP_PORTSC_BASE	0x400

#define XHCICMD_RUN			0
#define XHCICMD_HCRST		1
#define XHCICMD_IE			2
#define XHCISTS_HCH			0
#define XHCISTS_CNR			11
#define XHCISTS_EINT		3

#define XHCIPORT_CCS		0
#define XHCIPORT_PED		1
#define XHCIPORT_PR			4
#define XHCIPORT_CSC		17

// TRB types
#define XHCI_TRB_NORMAL		1
#define XHCI_TRB_SETUP		2
#define XHCI_TRB_DATA		3
#define XHCI_TRB_STATUS		4
#define XHCI_TRB_LINK		6
#define XHCI_TRB_CMD_NOOP	8
#define XHCI_TRB_CMD_ENABLE_SLOT	9
#define XHCI_TRB_CMD_DISABLE_SLOT	10
#define XHCI_TRB_CMD_ADDR_DEV		11
#define XHCI_TRB_CMD_CONF_EP		12
#define XHCI_TRB_CMD_EVAL_CONTEXT	13
#define XHCI_TRB_CMD_SET_DEQ		16
#define XHCI_TRB_EVT_TRANSFER		32
#define XHCI_TRB_EVT_CMD_COMP		33
#define XHCI_TRB_EVT_PORT_STS		34

#define XHCI_CC_SUCCESS		1
#define XHCI_CC_STALL		6
#define XHCI_CC_SHORT_PACKET	13

#define XHCI_TRB_IOC		5
#define XHCI_TRB_IDT		6
#define XHCI_TRB_DIR_IN		16
#define XHCI_TRB_TRT_OUT	(2 << 16)
#define XHCI_TRB_TRT_IN		(3 << 16)

#define XHCI_RING_SIZE		64
#define XHCI_RING_LINK_IDX	63
#define XHCI_MAX_PACKET		64
#define XHCI_CTX_SIZE		2048
#define XHCI_INPUT_CTX_SIZE	4096

class CXHCITrb
{
	U64 param;
	U32 status;
	U32 control;
};

public class CUSBStateGlobals
{
	U8		*xhci_base;
	I64		 bdf;
	I64		 cap_length;
	I64		 runtime_off;
	I64		 db_off;
	I64		 ctx_size;
	I64		 max_ports;
	I64		 max_slots;
	I64		 page_size;
	I64		 irq;

	U8		*dcbaa;
	U64		 dcbaa_phys;
	U8		*cmd_ring;
	U8		*evt_ring;
	U8		*evt_erst;
	U64		 cmd_ring_phys;
	U64		 evt_ring_phys;
	U64		 evt_erst_phys;
	I64		 cmd_ring_idx;
	I64		 cmd_ring_cycle;
	I64		 evt_ring_idx;
	I64		 evt_ring_cycle;

	U8		*dev_ctx;
	U64		 dev_ctx_phys;
	U8		*input_ctx;
	U64		 input_ctx_phys;
	U8		*ctrl_buf;
	U64		 ctrl_buf_phys;
	U8		*ep0_ring;
	U64		 ep0_ring_phys;
	I64		 ep0_ring_idx;
	I64		 ep0_ring_cycle;
	I64		 enum_slot;

	U8		*kbd_ring;
	U64		 kbd_ring_phys;
	I64		 kbd_ring_idx;
	I64		 kbd_ring_cycle;
	I64		 kbd_slot;
	I64		 kbd_ep;
	I64		 kbd_dci;
	I64		 kbd_iface;
	I64		 kbd_max_pkt;
	U8		 kbd_last_rpt[8];
	Bool	 kbd_pending;
	I64		 kbd_submit_count;
	I64		 kbd_evt_count;
	I64		 kbd_report_count;
	I64		 kbd_inject_count;
	I64		 kbd_last_len;
	I64		 kbd_last_code;
	U8		 kbd_last_bytes[16];

	U8		*ms_ring;
	U64		 ms_ring_phys;
	I64		 ms_ring_idx;
	I64		 ms_ring_cycle;
	I64		 ms_slot;
	I64		 ms_ep;
	I64		 ms_dci;
	I64		 ms_iface;
	I64		 ms_max_pkt;
	U64		 ms_buf_phys;
	U64		 kbd_buf_phys;
	Bool	 ms_pending;
	I64		 ms_acc_x;
	I64		 ms_acc_y;
	I64		 ms_acc_z;
	I64		 ms_acc_b;
	I64		 ms_last_btn;
	Bool	 ms_abs;
	Bool	 ms_abs_seen;
	I64		 ms_abs_x;
	I64		 ms_abs_y;
	I64		 ms_last_abs_x;
	I64		 ms_last_abs_y;
	U8		 ms_last_bytes[16];
	I64		 ms_last_len;
	I64		 ms_xfer_code;
	I64		 kbd_xfer_code;
	Bool	 kbd_xfer_done;
	Bool	 ms_xfer_done;
	I64		 kbd_xfer_len;
	I64		 ms_xfer_len;

	Bool	 cmd_comp_done;
	I64		 cmd_comp_slot;
	I64		 cmd_comp_code;
	Bool	 xfer_done;
	I64		 xfer_len;
	I64		 xfer_code;
	Bool	 port_event;
	Bool	 active;
};
