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
CREATE OR REPLACE FUNCTION shortest_distance_route(start_lon double precision, start_lat double precision, end_lon double precision, end_lat double precision)
RETURNS text AS $$
DECLARE
	route text;
BEGIN
	SELECT ST_AsEncodedPolyline(
		ST_SetPoint(
			ST_SetPoint(
				(SELECT ST_MakeLine(ways.the_geom) FROM pgr_trsp('SELECT gid::integer as id, source::integer, target::integer, cost::float FROM ways',
						(SELECT id from closest_road_to_point(start_lon, start_lat))::integer,
						(SELECT ST_LineLocatePoint((SELECT road from closest_road_to_point(start_lon, start_lat)), (SELECT ST_GeometryFromText('POINT('||start_lon||' '||start_lat||')',4326)))),
						(SELECT id from closest_road_to_point(end_lon, end_lat))::integer,
						(SELECT ST_LineLocatePoint((SELECT road from closest_road_to_point(end_lon, end_lat)), (SELECT ST_GeometryFromText('POINT('||end_lon||' '||end_lat||')',4326)))),
						true, false) INNER JOIN ways on ways.gid = id2),
				0,
				(ST_LineInterpolatePoint(
						(SELECT the_geom from ways where gid = (SELECT id from closest_road_to_point(start_lon, start_lat))),
						(SELECT ST_LineLocatePoint((SELECT road from closest_road_to_point(start_lon, start_lat)), (SELECT ST_GeometryFromText('POINT('||start_lon||' '||start_lat||')',4326))))
				))
		),
		-1,
		(ST_LineInterpolatePoint(
				(SELECT the_geom from ways where gid = (SELECT id from closest_road_to_point(end_lon, end_lat))),
				(SELECT ST_LineLocatePoint((SELECT road from closest_road_to_point(end_lon, end_lat)), (SELECT ST_GeometryFromText('POINT('||end_lon||' '||end_lat||')',4326))))
		))
)
		) INTO route;
		RETURN route;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION vertex_from_point(lo double precision, la double precision)
RETURNS integer AS $$
DECLARE
	node integer;
BEGIN
	SELECT n.id INTO node
	FROM ways_vertices_pgr n
	ORDER BY n.the_geom <-> ST_GeometryFromText('POINT('||lo||' '||la||')', 4326)
	LIMIT 1;
	RETURN node;
END;
$$ LANGUAGE plpgsql;

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

CREATE TYPE closest_road AS (id bigint, distance double precision, road geometry);
CREATE OR REPLACE FUNCTION closest_road_to_point(lon double precision, lat double precision)
RETURNS TABLE (id bigint, distance double precision, road geometry) AS $$
DECLARE
  road closest_road;
BEGIN
  RETURN QUERY
    SELECT gid as id
    , ST_Distance(ST_GeomFromText('POINT('||lon||' '||lat||')',4326), the_geom) AS distance
    , the_geom as road
  FROM ways
  ORDER BY distance ASC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql;








CREATE OR REPLACE FUNCTION shortest_distance_route(start_lon double precision, start_lat double precision, end_lon double precision, end_lat double precision)
RETURNS text AS $$
DECLARE
	route text;
BEGIN
	SELECT ST_AsEncodedPolyline(
    (SELECT ST_MakeLine(ways.the_geom) FROM pgr_astar('SELECT gid::integer as id, source::integer, target::integer, cost::float, reverse_cost::float, x1, y1, x2, y2 FROM ways',
        (SELECT vertex_from_point(start_lon, start_lat)::integer),
        (SELECT vertex_from_point(end_lon, end_lat)::integer),
    ) INNER JOIN ways on ways.gid = edge)
		) INTO route;
		RETURN route;
END;
$$ LANGUAGE plpgsql;

