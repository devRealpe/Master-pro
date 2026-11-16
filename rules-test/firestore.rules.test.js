// Pruebas de firestore.rules contra el emulador. Se ejecutan con `npm test`
// desde esta carpeta; el proyecto «demo-» no toca ningún dato real.
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, it } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { deleteDoc, doc, getDoc, setDoc } from 'firebase/firestore';

const OWNER = 'ana';
const OTHER = 'intruso';

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-master-pro',
    firestore: {
      rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
    },
  });
});

beforeEach(async () => {
  await env.clearFirestore();
  // Datos de partida, escritos sin pasar por las reglas.
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, `users/${OWNER}`), { displayName: 'Ana Pérez' });
    await setDoc(doc(db, `users/${OWNER}/subjects/s1`), { name: 'Asignatura 1' });
    await setDoc(doc(db, `users/${OWNER}/activities/a1/attachments/x`), { n: 1 });
  });
});

after(async () => {
  await env.cleanup();
});

describe('La persona dueña', () => {
  const db = () => env.authenticatedContext(OWNER).firestore();

  it('lee y escribe su perfil', async () => {
    await assertSucceeds(getDoc(doc(db(), `users/${OWNER}`)));
    await assertSucceeds(setDoc(doc(db(), `users/${OWNER}`), { displayName: 'Ana' }));
  });

  it('lee, crea y borra en sus colecciones, a cualquier profundidad', async () => {
    await assertSucceeds(getDoc(doc(db(), `users/${OWNER}/subjects/s1`)));
    await assertSucceeds(setDoc(doc(db(), `users/${OWNER}/subjects/s2`), { name: 'Otra' }));
    await assertSucceeds(getDoc(doc(db(), `users/${OWNER}/activities/a1/attachments/x`)));
    await assertSucceeds(deleteDoc(doc(db(), `users/${OWNER}/subjects/s1`)));
  });

  it('no puede escribir fuera de su árbol', async () => {
    await assertFails(setDoc(doc(db(), `users/${OTHER}/subjects/s1`), { name: 'x' }));
    await assertFails(setDoc(doc(db(), 'config/global'), { a: 1 }));
    await assertFails(getDoc(doc(db(), 'config/global')));
  });
});

describe('Otra persona con sesión', () => {
  const db = () => env.authenticatedContext(OTHER).firestore();

  it('no lee ni escribe datos ajenos', async () => {
    await assertFails(getDoc(doc(db(), `users/${OWNER}`)));
    await assertFails(getDoc(doc(db(), `users/${OWNER}/subjects/s1`)));
    await assertFails(setDoc(doc(db(), `users/${OWNER}/subjects/s1`), { name: 'x' }));
    await assertFails(deleteDoc(doc(db(), `users/${OWNER}/subjects/s1`)));
  });
});

describe('Sin sesión', () => {
  const db = () => env.unauthenticatedContext().firestore();

  it('no lee ni escribe nada', async () => {
    await assertFails(getDoc(doc(db(), `users/${OWNER}`)));
    await assertFails(getDoc(doc(db(), `users/${OWNER}/subjects/s1`)));
    await assertFails(setDoc(doc(db(), `users/${OWNER}/subjects/s9`), { name: 'x' }));
    await assertFails(setDoc(doc(db(), 'users/anonimo'), { a: 1 }));
  });
});
