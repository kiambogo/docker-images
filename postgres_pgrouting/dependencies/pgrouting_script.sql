alter table planet_osm_line add column source int4;
alter table planet_osm_line add column target int4;

select pgr_createTopology('planet_osm_line', 0.000001, 'way', 'osm_id');
select pgr_nodeNetwork('planet_osm_line', 0.000001, 'osm_id', 'way');
select pgr_createTopology('planet_osm_line_noded', 0.000001, 'way', 'id');

alter table planet_osm_line_noded add column name text, add column type text, add column oneway text, add column surface text, add column bicycle text;

update planet_osm_line_noded as new set name = case when old.name is null then old.ref else old.name end, type = old.highway, oneway = old.oneway, surface = old.surface, bicycle = old.bicycle from planet_osm_line as old where new.old_id = old.osm_id;

alter table planet_osm_line_noded add distance float8;

update planet_osm_line_noded set distance = ST_Length(way) / 1000;



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
    SELECT planet_osm_line_noded.id
    , ST_Distance(ST_GeomFromText('POINT('||lon||' '||lat||')',4326), way) AS distance
    , way as road
  FROM planet_osm_line_noded
  ORDER BY distance ASC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION shortest_distance_route(start_lon double precision, start_lat double precision, end_lon double precision, end_lat double precision)
RETURNS TABLE (x double precision, y double precision) AS $$
DECLARE
	route text;
BEGIN
  RETURN QUERY
  WITH start_road      AS (SELECT * from closest_road_to_point(start_lon, start_lat)),
       end_road        AS (SELECT * from closest_road_to_point(end_lon, end_lat)),
       start_point     AS (SELECT ST_GeometryFromText('POINT('||start_lon||' '||start_lat||')',4326)),
       end_point       AS (SELECT ST_GeometryFromText('POINT('||end_lon||' '||end_lat||')',4326)),
       route           AS (SELECT * from pgr_trsp('SELECT id::integer, source::integer, target::integer, distance::float8 as cost FROM planet_osm_line_noded',
                          (SELECT id from start_road)::integer,
                          (SELECT ST_LineLocatePoint((SELECT road from start_road), (SELECT * FROM start_point))),
                          (SELECT id from end_road)::integer,
                          (SELECT ST_LineLocatePoint((SELECT road from end_road), (SELECT * FROM end_point))),
                          true, false) AS r INNER JOIN planet_osm_line_noded as ways on ways.id = r.id2
                          where r.seq <> 1 and r.id2 <> ((SELECT id from end_road)::integer)),
       corrected_start AS (SELECT ST_SetPoint((SELECT ST_MakeLine(result.way) FROM route AS result), 0,
                          (ST_LineInterpolatePoint(
                          (SELECT way from planet_osm_line_noded where id = (SELECT id from start_road)),
                          (SELECT ST_LineLocatePoint((SELECT road from start_road), (SELECT * FROM start_point))))))),
       corrected_path  AS (SELECT ST_SetPoint((SELECT * FROM corrected_start), -1, (ST_LineInterpolatePoint(
                          (SELECT way from planet_osm_line_noded where id = (SELECT id from end_road)),
                          (SELECT ST_LineLocatePoint((SELECT road from end_road), (SELECT * FROM end_point))))))),
       result          AS (SELECT ST_X((ST_dumppoints((SELECT * FROM corrected_path))).geom), ST_Y((ST_dumppoints((SELECT * FROM corrected_path))).geom))
  SELECT * from result;
END;
$$ LANGUAGE plpgsql;

