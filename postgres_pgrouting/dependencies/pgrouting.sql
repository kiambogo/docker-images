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


CREATE TYPE shortest_route AS (distance double precision, route varchar(2000));
CREATE OR REPLACE FUNCTION shortest_distance_route(start_x double precision, start_y double precision, end_x double precision, end_y double precision)
RETURNS TABLE (distance double precision, route geometry) AS $$
DECLARE
	route shortest_route;
BEGIN
    RETURN QUERY
    WITH closest_road AS (SELECT closest_road(start_x, start_y))
  FROM ways
    WITH result AS (
        select seq, id1 as node, id2 as way, 'POINT('||lo||' '||la||')'cost as length FROM pgr_astar('
            SELECT gid AS id,
                source::integer,
                target::integer,
                length::double precision AS c'POINT('||lo||' '||la||')'ost,
                x1, y1, x2, y2
            FROM ways',
        n1, n2, false, false)
        order by seq asc


SELECT ST_Line_Locate_Point(
  ()
 ,()
)

--GOOD
CREATE OR REPLACE FUNCTION vertex_from_point('POINT('||lo||' '||la||')'lo double precision, la double precision)
RETURNS integer AS $$
DECLARE
	node integer;
BEGIN
	SELECT n.id INTO node
	FROM ways_vertices_pgr n
	ORDER BY n.the_geom <-> ST_GeometryFromText('POINT('||lo||' '||la||')''POINT('||lo||' '||la||')', 4326)
	LIMIT 1;
	RETURN node;
END;
$$ LANGUAGE plpgsql;

-- GOOD
CREATE TYPE closest_point AS (x double precision, y double precision);
CREATE OR REPLACE FUNCTION closest_point_on_road(lon double precision, lat double precision)
RETURNS TABLE (x double precision, y double precision) AS $$
DECLARE
	w closest_point;
BEGIN
  RETURN QUERY
  SELECT ST_X(p) as x, ST_Y(p) as y
  -- ST_LineLocatePoint
    FROM ST_ClosestPoint(
      (SELECT road from closest_road_to_point(lon, lat)),
      (SELECT ST_GeometryFromText('POINT('||lon||' '||lat||')',4326))
    ) AS p
  LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- GOOD
CREATE TYPE closest_road AS (id bigint, distance double precision, road geometry);
CREATE OR REPLACE FUNCTION closest_road_to_point(lon double precision, lat double precision)
RETURNS TABLE (id bigint, distance double precision, road geometry) AS $$
DECLARE
  road closest_road;
BEGIN
  RETURN QUERY
    SELECT gid as id
    , ST_Distance(ST_GeomFromText('POINT(-79.859501 43.233569)',4326), the_geom) AS distance
    , the_geom as road
  FROM ways
  ORDER BY distance ASC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql;
