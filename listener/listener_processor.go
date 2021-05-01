package listener

import (
	"database/sql"
	"log"
)

func ProcessNewStatement(db *sql.DB, statementExecuted string) {
	q := `
	SELECT
		TABLE_NAME,
		data,
		statement
	FROM
		dumbo.outbound_event_queue
	WHERE
		"statement"= $1
		AND processed = FALSE
	ORDER BY
		created_at ASC
	LIMIT 1;
	`
	row, err := db.Query(q, statementExecuted)
	if err != nil {
		log.Fatal(err)
	}
	for row.Next() {
		var (
			tableName string
			jsonData  []byte
			statement string
		)
		if err := row.Scan(&tableName, &jsonData, &statement); err != nil {
			log.Fatal(err)
		}
		// TODO: send this to Kafka
		log.Printf("Table: %s with data changes %s\n", tableName, jsonData)
	}

}
