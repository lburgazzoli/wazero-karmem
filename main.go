package main

import (
	"bytes"
	_ "embed"
	"fmt"

	"github.com/lburgazzoli/wazero-karmem/pkg/wasm"

	"context"

	"github.com/lburgazzoli/wazero-karmem/pkg/interop"
	"github.com/rs/xid"
	karmem "karmem.org/golang"
)

//go:embed etc/fn/process.wasm
var wasmContent []byte

//
// NOTES:
//   https://github.com/tinygo-org/tinygo/issues/2787
//

func main() {

	ctx := context.Background()

	r, err := wasm.NewRuntime(ctx, wasm.Options{})
	if err != nil {
		panic(err)
	}

	defer func() { _ = r.Close(ctx) }()

	f, err := r.Load(ctx, "process", bytes.NewReader(wasmContent))
	if err != nil {
		panic(err)
	}

	w := karmem.NewWriter(1024)

	in := interop.Message{ID: xid.New().String()}

	_, err = in.WriteAsRoot(w)
	if err != nil {
		panic(err)
	}

	out, err := f.Invoke(ctx, w.Bytes())
	if err != nil {
		panic(err)
	}

	reader := karmem.NewReader(out)
	decoded := interop.NewMessageViewer(reader, 0)

	fmt.Printf("process -> id: %s, content: %s\n", decoded.ID(reader), string(decoded.Content(reader)))
}
