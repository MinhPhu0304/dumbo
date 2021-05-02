package listener

import (
	"database/sql"
	"log"

	"github.com/minhphu0304/dumbo/producer"
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
		kafkaMsg := &producer.DatabaseEvent{
			TableName: tableName,
			JsonData:  jsonData,
			Statement: statement,
		}
		producer.ProduceEvent(*kafkaMsg)
	}

}
