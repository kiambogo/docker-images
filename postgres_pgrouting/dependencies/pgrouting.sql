CREATE TYPE tri_route AS (distance double precision, route varchar(2000));

CREATE OR REPLACE FUNCTION tri_route_1 (n1 INTEGER, n2 INTEGER)
RETURNS TABLE (distance double precision, the_geom geometry) AS $$

DECLARE
    route tri_route;
BEGIN
    RETURN QUERY
    WITH result AS (
        select seq, id1 as node, id2 as way, cost as length FROM pgr_astar('
            SELECT gid AS id,
                source::integer,
                target::integer,
                length::double precision AS cost,
                x1, y1, x2, y2
            FROM ways',
        n1, n2, false, false)
        order by seq asc
    )
    SELECT
        sum(length) as distance, ST_UNION(v.the_geom) as geoms
    FROM result r
    INNER JOIN ways_vertices_pgr v ON v.id = r.node;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION tri_nearest(y1 double precision, x1 double precision)
RETURNS integer AS $$

DECLARE
	node integer;
BEGIN
	SELECT n.id INTO node
	FROM ways_vertices_pgr n
	ORDER BY n.the_geom <-> ST_GeometryFromText('POINT('||x1||' '||y1||')', 4326)
	LIMIT 1;
	RETURN node;
END;
$$ LANGUAGE plpgsql;
