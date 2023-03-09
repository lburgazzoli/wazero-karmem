// nolint
package main

import (
	"reflect"
	"unsafe"

	"github.com/lburgazzoli/wazero-karmem/pkg/interop"

	karmem "karmem.org/golang"
)

// main is required for TinyGo to compile to Wasm.
func main() {}

//export process
func _process(ptr uint32, size uint32) uint64 {
	in := ptrToMessage(ptr, size)

	in.Content = []byte("hello from wasm")

	p, s := messageToPtr(in)

	return (uint64(p) << uint64(32)) | uint64(s)
}

func ptrToMessage(ptr uint32, size uint32) interop.Message {
	data := *(*[]byte)(unsafe.Pointer(&reflect.SliceHeader{
		Data: uintptr(ptr),
		Len:  uintptr(size),
		Cap:  uintptr(size),
	}))

	reader := karmem.NewReader(data)
	decoded := interop.NewMessageViewer(reader, 0)

	return interop.Message{
		ID:            decoded.ID(reader),
		Source:        decoded.Source(reader),
		Type:          decoded.Type(reader),
		Subject:       decoded.Subject(reader),
		ContentType:   decoded.ContentType(reader),
		ContentSchema: decoded.ContentSchema(reader),
		Time:          decoded.Time(),
		Content:       decoded.Content(reader),
	}
}

func messageToPtr(msg interop.Message) (uint32, uint32) {
	w := karmem.NewWriter(1024)
	if _, err := msg.WriteAsRoot(w); err != nil {
		panic(err)
	}

	buf := w.Bytes()
	ptr := &buf[0]
	unsafePtr := uintptr(unsafe.Pointer(ptr))

	return uint32(unsafePtr), uint32(len(buf))
}
