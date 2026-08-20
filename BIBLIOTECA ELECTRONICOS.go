package main

import (
	"bufio"
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"os/exec"
	"strings"
	"time"

	"biblioteca-web/repositorio"
	"biblioteca-web/servicio"
	"biblioteca-web/web"
)

func hacerPeticion(metodo, ruta, cuerpo string) {
	cliente := &http.Client{Timeout: 5 * time.Second}
	var body io.Reader
	if cuerpo != "" {
		body = strings.NewReader(cuerpo)
	}
	req, err := http.NewRequest(metodo, "http://localhost:8080"+ruta, body)
	if err != nil {
		fmt.Println("error:", err)
		return
	}
	if cuerpo != "" {
		req.Header.Set("Content-Type", "application/json")
	}
	resp, err := cliente.Do(req)
	if err != nil {
		fmt.Println("error:", err)
		return
	}
	defer resp.Body.Close()
	fmt.Println("Status:", resp.Status)
	var v any
	if err := json.NewDecoder(resp.Body).Decode(&v); err == nil {
		var buf bytes.Buffer
		enc := json.NewEncoder(&buf)
		enc.SetIndent("", "  ")
		if err := enc.Encode(v); err == nil {
			fmt.Print(buf.String())
		}
	}
}

func ejecutarPruebas() {
	cmd := exec.Command("go", "test", "./...", "-v", "-race")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Run()
}

func mostrarMenu() {
	fmt.Println("=============================================")
	fmt.Println("  MENU DEMO - Biblioteca Web (API REST)")
	fmt.Println("=============================================")
	fmt.Println("  1. Crear usuario")
	fmt.Println("  2. Crear libro")
	fmt.Println("  3. Listar libros")
	fmt.Println("  4. Filtrar por genero")
	fmt.Println("  5. Prestar libro")
	fmt.Println("  6. Segundo prestamo (409)")
	fmt.Println("  7. Historial del usuario")
	fmt.Println("  8. Devolver libro")
	fmt.Println("  9. Importar 3 libros (concurrencia)")
	fmt.Println("  t. Ejecutar pruebas (go test ./... -v -race)")
	fmt.Println("  0. Salir")
	fmt.Println("=============================================")
}

func main() {
	libros := repositorio.NuevoRepositorioLibrosMemoria()
	usuarios := repositorio.NuevoRepositorioUsuariosMemoria()
	prestamos := repositorio.NuevoRepositorioPrestamosMemoria()

	svc := servicio.NuevoBibliotecaService(libros, usuarios, prestamos)
	router := web.NuevoRouter(svc)

	servidor := &http.Server{
		Addr:         ":8080",
		Handler:      router,
		ReadTimeout:  5 * time.Second,
		WriteTimeout: 10 * time.Second,
	}

	go func() {
		log.Println("Servidor de biblioteca escuchando en http://localhost:8080")
		log.Fatal(servidor.ListenAndServe())
	}()

	time.Sleep(300 * time.Millisecond)

	mostrarMenu()
	lector := bufio.NewReader(os.Stdin)
	for {
		fmt.Print("Elige una opcion (0-9, t): ")
		linea, err := lector.ReadString('\n')
		if err != nil {
			fmt.Println("Adios!")
			return
		}
		opcion := strings.TrimSpace(linea)
		switch opcion {
		case "1":
			hacerPeticion("POST", "/api/usuarios", `{"nombre":"Angel Ramirez","email":"angel@gmail.com","fecha":""}`)
		case "2":
			hacerPeticion("POST", "/api/libros", `{"año":2026,"titulo":"Programacion en Go","autor":"Google","genero":"Tecnologia","formato":"PDF","tamanoMB":2.5}`)
		case "3":
			hacerPeticion("GET", "/api/libros", "")
		case "4":
			hacerPeticion("GET", "/api/libros/genero/Tecnologia", "")
		case "5":
			hacerPeticion("POST", "/api/prestamos", `{"titulo":"Programacion en Go","usuarioId":1,"fecha":""}`)
		case "6":
			hacerPeticion("POST", "/api/prestamos", `{"titulo":"Programacion en Go","usuarioId":1,"fecha":""}`)
		case "7":
			hacerPeticion("GET", "/api/usuarios/1/historial", "")
		case "8":
			hacerPeticion("POST", "/api/prestamos/1/devolver", `{}`)
		case "9":
			hacerPeticion("POST", "/api/libros/importar", `{"libros":[{"año":2025,"titulo":"Libro 1","autor":"Autor 1","genero":"Ficcion","formato":"PDF","tamanoMB":1.0},{"año":2025,"titulo":"Libro 2","autor":"Autor 2","genero":"Ciencia","formato":"EPUB","tamanoMB":2.0},{"año":2025,"titulo":"Libro 3","autor":"Autor 3","genero":"Historia","formato":"PDF","tamanoMB":3.0}]}`)
		case "t":
			ejecutarPruebas()
		case "0":
			fmt.Println("Adios!")
			return
		default:
			fmt.Println("Opcion invalida. Escribe un numero del 0 al 9 o la letra t.")
		}
		fmt.Println()
	}
}