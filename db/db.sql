DROP TABLE words;
CREATE TABLE words (
    id   INTEGER PRIMARY KEY,
    word TEXT,
    pos  TEXT,
    UNIQUE(word, pos) ON CONFLICT IGNORE
);

DROP TABLE states;
CREATE TABLE states (
    id   INTEGER PRIMARY KEY,
    wid  INTEGER,
    next INTEGER
);

DROP TABLE states3;
CREATE TABLE states3 (
    id   INTEGER PRIMARY KEY,
    wid1 INTEGER,
    wid2 INTEGER,
    next INTEGER
);

-- DROP TABLE next;
-- CREATE TABLE next (
--     sid INTEGER,
--     wid INTEGER
-- );

