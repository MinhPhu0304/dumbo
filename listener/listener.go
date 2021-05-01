package listener

import (
	"database/sql"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/lib/pq"
)

func reportDBError(ev pq.ListenerEventType, err error) {
	if err != nil {
		fmt.Println(err.Error())
		return
	}
}

func ListenDBEvent(db *sql.DB) {
	listener := pq.NewListener("user="+os.Getenv("database_user")+" password="+os.Getenv("database_password")+" dbname="+os.Getenv("database")+" sslmode=disable", 1*time.Second, 15*time.Second, reportDBError)
	err := listener.Listen("outbound_event_queue")
	if err != nil {
		log.Fatalln(err)
		return
	}
	defer func() {
		if cerr := listener.Close(); cerr != nil {
			panic(err)
		}
		log.Println("Closed listener")
	}()
	fmt.Println("Start monitoring PostgreSQL...")
	waitForNotification(listener, db)
}

func waitForNotification(l *pq.Listener, db *sql.DB) {
	for {
		select {
		case n := <-l.Notify:
			fmt.Println("Received data from channel [", n.Channel, "] :")
			ProcessNewStatement(db, string(n.Extra))
		case <-time.After(30 * time.Minute):
			fmt.Println("Received no events for 90 seconds, checking connection")
			go func() {
				l.Ping()
			}()
			return
		}
	}
}
