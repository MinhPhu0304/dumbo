package main

import (
	"database/sql"
	"log"
	"os"

	"github.com/joho/godotenv"
	_ "github.com/lib/pq"
	"github.com/pressly/goose"
)

func main() {
	err := godotenv.Load()
	if err != nil {
		log.Fatal("Error loading .env file")
	}

	executeDBMigration()
}

func executeDBMigration() {
	connStr := "postgres://" + os.Getenv("database_user") + ":" + os.Getenv("database_password") + "@" + os.Getenv("database_host") + "/" + os.Getenv("database") + "?sslmode=disable"
	db, err := sql.Open("postgres", connStr)
	db.Ping()
	if err != nil {
		log.Fatal(err)
	}
	defer func() {
		if err := db.Close(); err != nil {
			log.Fatalf("goose: failed to close DB: %v\n", err)
		}
	}()

	if err := goose.Up(db, "./migrations"); err != nil {
		log.Printf("goose %v", err)
		log.Fatalln(err)
	}
}
