-- hotfix_data.TableHash must be the DB2 file tableHash, not DB2Meta layoutHash.
-- ItemSparse.db2 tableHash 0x919BE54E. BroadcastText.db2 tableHash 0x021826BB.

UPDATE `hotfix_data`
SET `TableHash` = 2442913102
WHERE `Id` BETWEEN 791001 AND 791052
  AND `RecordId` BETWEEN 177955 AND 178015;

UPDATE `hotfix_data`
SET `TableHash` = 35137211
WHERE `Id` = 791053
  AND `RecordId` = 201785;
