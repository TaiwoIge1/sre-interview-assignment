import { build } from '../server';
import { FastifyInstance } from 'fastify';
import supertest from 'supertest';
jest.mock('../repositories/planet.repository', () => {
  // Create a simple in-memory "database"
  const planetStatus = {
    '1': false,  // Tatooine - not destroyed
    '2': true    // Alderaan - destroyed
  };

  return {
    PlanetRepository: jest.fn().mockImplementation(() => {
      return {
        getPlanetDestructionStatus: jest.fn().mockImplementation((id) => {
          return Promise.resolve(planetStatus[id] !== undefined ? planetStatus[id] : null);
        }),
        upsertPlanetDestructionStatus: jest.fn().mockImplementation((id, destroyed) => {
          planetStatus[id] = destroyed;
          return Promise.resolve();
        })
      };
    })
  };
});

jest.mock('../adapters/swapi.adapter', () => {
  const speciesData = [
    {
      name: 'Human',
      classification: 'mammal',
      designation: 'sentient',
      average_height: '180',
      skin_colors: 'caucasian, black, asian, hispanic',
      hair_colors: 'blonde, brown, black, red',
      eye_colors: 'brown, blue, green, hazel, grey, amber',
      average_lifespan: '120',
      homeworld: 'https://swapi.dev/api/planets/1/',
      language: 'Galactic Basic',
      people: ['https://swapi.dev/api/people/1/'],
      films: ['https://swapi.dev/api/films/1/'],
      created: '2014-12-09T13:50:49.641000Z',
      edited: '2014-12-20T20:58:18.411000Z',
      url: 'https://swapi.dev/api/species/1/'
    },
    {
      name: 'Wookie',
      classification: 'mammal',
      designation: 'sentient',
      average_height: '210',
      skin_colors: 'gray',
      hair_colors: 'black, brown',
      eye_colors: 'blue, green, yellow, brown, golden, red',
      average_lifespan: '400',
      homeworld: 'https://swapi.dev/api/planets/2/',
      language: 'Shyriiwook',
      people: ['https://swapi.dev/api/people/13/'],
      films: ['https://swapi.dev/api/films/1/'],
      created: '2014-12-10T16:44:31.486000Z',
      edited: '2014-12-20T21:36:42.142000Z',
      url: 'https://swapi.dev/api/species/2/'
    }
  ];

  const planetData = {
    '1': {
      name: 'Tatooine',
      rotation_period: '23',
      orbital_period: '304',
      diameter: '10465',
      climate: 'arid',
      gravity: '1 standard',
      terrain: 'desert',
      surface_water: '1',
      population: '200000',
      residents: ['https://swapi.dev/api/people/1/'],
      films: ['https://swapi.dev/api/films/1/'],
      created: '2014-12-09T13:50:49.641000Z',
      edited: '2014-12-20T20:58:18.411000Z',
      url: 'https://swapi.dev/api/planets/1/'
    },
    '2': {
      name: 'Alderaan',
      rotation_period: '24',
      orbital_period: '364',
      diameter: '12500',
      climate: 'temperate',
      gravity: '1 standard',
      terrain: 'grasslands, mountains',
      surface_water: '40',
      population: '2000000000',
      residents: ['https://swapi.dev/api/people/5/'],
      films: ['https://swapi.dev/api/films/1/'],
      created: '2014-12-10T11:35:48.479000Z',
      edited: '2014-12-20T20:58:18.420000Z',
      url: 'https://swapi.dev/api/planets/2/'
    }
  };

  return {
    SwapiAdapter: jest.fn().mockImplementation(() => {
      return {
        getSpecies: jest.fn().mockImplementation((id) => {
          const species = speciesData.find(s => s.url.endsWith(`/${id}/`));
          if (!species) {
            return Promise.reject(new Error(`Species with ID ${id} not found`));
          }
          return Promise.resolve(species);
        }),
        getAllSpecies: jest.fn().mockResolvedValue(speciesData),
        getPlanet: jest.fn().mockImplementation((id) => {
          const planet = planetData[id];
          if (!planet) {
            return Promise.reject(new Error(`Planet with ID ${id} not found`));
          }
          return Promise.resolve(planet);
        })
      };
    })
  };
});

describe('Basic API Integration Tests - Core Functionality', () => {
  let app: FastifyInstance;
  let request: any;

  beforeAll(async () => {
    app = build();
    await app.ready();
    request = supertest(app.server);
  });

  afterAll(async () => {
    await app.close();
  });

  test('GET /species should return all species with their homeworlds', async () => {
    const response = await request.get('/species');

    expect(response.status).toBe(201);
    expect(response.body).toHaveProperty('species');
    expect(Array.isArray(response.body.species)).toBe(true);
    expect(response.body.species.length).toBeGreaterThan(0);

    const species = response.body.species[0];
    expect(species).toHaveProperty('name');
    expect(species).toHaveProperty('classification');
    expect(species).toHaveProperty('designation');
    expect(species).toHaveProperty('average_height');

    const speciesWithHomeworld = response.body.species.find(s => s.homeworld);
    if (speciesWithHomeworld) {
      expect(speciesWithHomeworld.homeworld).toHaveProperty('name');
      expect(speciesWithHomeworld.homeworld).toHaveProperty('climate');
      expect(speciesWithHomeworld.homeworld).toHaveProperty('terrain');
      expect(speciesWithHomeworld.homeworld).toHaveProperty('destroyed');
    }
  });

  test('GET /species?sort=average_height&order=desc should return species sorted by height', async () => {
    const response = await request.get('/species?sort=average_height&order=desc');

    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('species');
    expect(Array.isArray(response.body.species)).toBe(true);

    expect(response.body.species[0].name).toBe('Wookie');
    expect(response.body.species[1].name).toBe('Human');
  });

  test('GET /species/:id should return a specific species with its homeworld', async () => {
    const response = await request.get('/species/1');

    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('species');
    expect(response.body.species).toHaveProperty('name', 'Human');
    expect(response.body.species).toHaveProperty('classification', 'mammal');

    expect(response.body.species.homeworld).toHaveProperty('name', 'Tatooine');
    expect(response.body.species.homeworld).toHaveProperty('destroyed', false);
  });

  test('PUT /planets/:id/destruction should update a planet\'s destruction status', async () => {
    const response = await request
      .put('/planets/1/destruction')
      .send({ destroyed: true });

    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('planet');
    expect(response.body.planet).toHaveProperty('destroyed', true);

    const verifyResponse = await request.get('/species/1');
    expect(verifyResponse.body.species.homeworld.destroyed).toBe(true);

    await request
      .put('/planets/1/destruction')
      .send({ destroyed: false });
  });
});