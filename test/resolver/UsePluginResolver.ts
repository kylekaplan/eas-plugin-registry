import { expect } from 'chai';
import { encodeBytes32String, Signer } from 'ethers';
import { ethers } from 'hardhat';
import { SchemaEncoder } from '@ethereum-attestation-service/eas-sdk';
import Contracts from '../../components/Contracts';
import { UsePluginResolver, PluginAttesterResolver, SchemaRegistry, TestEAS } from '../../typechain-types';
import { NO_EXPIRATION, ZERO_ADDRESS, ZERO_BYTES32 } from '../../utils/Constants';
import { getSchemaUID, getUIDFromAttestTx } from '../../utils/EAS';
import {
  expectAttestation,
  // expectFailedAttestation,
  // expectFailedMultiAttestations,
  expectMultiAttestations,
  expectMultiRevocations,
  expectRevocation,
  registerSchema
} from '../helpers/EAS';
import { latest } from '../helpers/Time';
import { createWallet } from '../helpers/Wallet';


describe('UsePluginResolver', () => {
  let accounts: Signer[];
  let recipient: Signer;
  let sender: Signer;

  let registry: SchemaRegistry;
  let eas: TestEAS;
  let usePluginResolver: UsePluginResolver; // UsePluginResolver is the contract we are testing
  let chosenPluginResolver: PluginAttesterResolver; // resolver that is connected to a pluginId
  let encodedData: string;

  const schema = 'bytes32 pluginId,bytes32 details';
  const schemaEncoder = new SchemaEncoder('bytes32 pluginId,bytes32 details');
  let schemaId: string;
  const expirationTime = NO_EXPIRATION;
  const detailsId = encodeBytes32String('detailsId');
  console.log('detailsId:', detailsId);

  const schema2 = 'bool isFriend';
  const schema2Id = getSchemaUID(schema2, ZERO_ADDRESS, true);

  before(async () => {
    accounts = await ethers.getSigners();

    [recipient] = accounts;
  });

  beforeEach(async () => {
    sender = await createWallet();

    registry = await Contracts.SchemaRegistry.deploy();
    eas = await Contracts.TestEAS.deploy(registry.getAddress());

    await eas.setTime(await latest());

    await registerSchema(schema2, registry, ZERO_ADDRESS, true);

    usePluginResolver = await Contracts.UsePluginResolver.deploy(eas.getAddress());
    expect(await usePluginResolver.isPayable()).to.be.false;

    schemaId = await registerSchema(schema, registry, usePluginResolver, true);

    chosenPluginResolver = await Contracts.PluginAttesterResolver.deploy(
      await eas.getAddress(),
      await sender.getAddress(), // setting it to the sender so it should be able to attest
    );
    const chosenPluginResolverAddress = await chosenPluginResolver.getAddress();
    console.log('chosenPluginResolver address:', chosenPluginResolverAddress);
    const tx = await usePluginResolver.setUpPluginAndAssignResolver(chosenPluginResolverAddress);
    const receipt = await tx.wait();
    // Check if logs exist and parse the first log
    if (receipt && receipt.logs && receipt.logs[0]) {
      const event = usePluginResolver.interface.parseLog({
        topics: [...receipt.logs[0].topics],
        data: receipt.logs[0].data
      });
      // Now you can access the event's name and arguments like this:
      const eventName = event?.name;
      const eventArgs = event?.args;
      console.log('eventName:', eventName);
      console.log('eventArgs:', eventArgs);
      const pluginId = eventArgs?.[0];
      console.log('pluginId:', pluginId);
      encodedData = schemaEncoder.encodeData([
        { name: 'pluginId', value: pluginId, type: 'bytes32' },
        { name: 'details', value: detailsId, type: 'bytes32' },
      ]);
    }
  });

  // context('non-existing attestation', () => {
  //   it('should revert', async () => {
  //     await expectFailedAttestation(
  //       {
  //         eas
  //       },
  //       schemaId,
  //       {
  //         recipient: await recipient.getAddress(),
  //         expirationTime
  //       },
  //       { from: sender },
  //       'InvalidAttestation'
  //     );

  //     const uid = await getUIDFromAttestTx(
  //       eas.attest({
  //         schema: schemaId,
  //         data: {
  //           recipient: await recipient.getAddress(),
  //           expirationTime,
  //           revocable: true,
  //           refUID: ZERO_BYTES32,
  //           data: '0x1234',
  //           value: 0
  //         }
  //       })
  //     );

  //     await expectFailedMultiAttestations(
  //       {
  //         eas
  //       },
  //       [
  //         {
  //           schema: schemaId,
  //           requests: [
  //             {
  //               recipient: await recipient.getAddress(),
  //               expirationTime
  //             },
  //             {
  //               recipient: await recipient.getAddress(),
  //               expirationTime,
  //               data: uid
  //             }
  //           ]
  //         }
  //       ],
  //       { from: sender },
  //       'InvalidAttestations'
  //     );

  //     await expectFailedMultiAttestations(
  //       {
  //         eas
  //       },
  //       [
  //         {
  //           schema: schemaId,
  //           requests: [
  //             {
  //               recipient: await recipient.getAddress(),
  //               expirationTime,
  //               data: uid
  //             },
  //             {
  //               recipient: await recipient.getAddress(),
  //               expirationTime
  //             }
  //           ]
  //         }
  //       ],
  //       { from: sender },
  //       'InvalidAttestations'
  //     );
  //   });
  // });

  // context('invalid attestation', () => {
  //   let uid: string;

  //   beforeEach(async () => {
  //     uid = await getUIDFromAttestTx(
  //       eas.attest({
  //         schema: schemaId,
  //         data: {
  //           recipient: await recipient.getAddress(),
  //           expirationTime,
  //           revocable: true,
  //           refUID: ZERO_BYTES32,
  //           data: '0x1234',
  //           value: 0
  //         }
  //       })
  //     );
  //   });

  //   it('should revert', async () => {
  //     await expectFailedAttestation(
  //       {
  //         eas
  //       },
  //       schemaId,
  //       {
  //         recipient: await recipient.getAddress(),
  //         expirationTime
  //       },
  //       { from: sender },
  //       'InvalidAttestation'
  //     );

  //     await expectFailedMultiAttestations(
  //       {
  //         eas
  //       },
  //       [
  //         {
  //           schema: schemaId,
  //           requests: [
  //             {
  //               recipient: await recipient.getAddress(),
  //               expirationTime
  //             },
  //             {
  //               recipient: await recipient.getAddress(),
  //               expirationTime,
  //               data: uid
  //             }
  //           ]
  //         }
  //       ],
  //       { from: sender },
  //       'InvalidAttestations'
  //     );

  //     await expectFailedMultiAttestations(
  //       {
  //         eas
  //       },
  //       [
  //         {
  //           schema: schemaId,
  //           requests: [
  //             {
  //               recipient: await recipient.getAddress(),
  //               expirationTime,
  //               data: uid
  //             },
  //             {
  //               recipient: await recipient.getAddress(),
  //               expirationTime
  //             }
  //           ]
  //         }
  //       ],
  //       { from: sender },
  //       'InvalidAttestations'
  //     );
  //   });
  // });

  context('valid attestation', () => {
    let uid: string;

    beforeEach(async () => {
      console.log('encodedData:', encodedData);
      uid = await getUIDFromAttestTx(
        eas.attest({
          schema: schema2Id,
          data: {
            recipient: await recipient.getAddress(),
            expirationTime,
            revocable: true,
            refUID: ZERO_BYTES32,
            data: encodedData,
            value: 0
          }
        })
      );
    });

    it('should allow attesting', async () => {
      const { uid: uid2 } = await expectAttestation(
        { eas },
        schemaId,
        { recipient: await recipient.getAddress(), expirationTime, data: uid },
        { from: sender }
      );

      await expectRevocation({ eas }, schemaId, { uid: uid2 }, { from: sender });

      const { uids } = await expectMultiAttestations(
        { eas },
        [
          {
            schema: schemaId,
            requests: [
              { recipient: await recipient.getAddress(), expirationTime, data: uid },
              { recipient: await recipient.getAddress(), expirationTime, data: uid }
            ]
          }
        ],
        { from: sender }
      );

      await expectMultiRevocations(
        { eas },
        [
          {
            schema: schemaId,
            requests: uids.map((uid) => ({ uid }))
          }
        ],
        { from: sender }
      );
    });
  });

  describe('byte utils', () => {
    it('should revert on invalid input', async () => {
      await expect(usePluginResolver.toBytes32('0x1234', 1000)).to.be.revertedWithCustomError(usePluginResolver, 'OutOfBounds');
    });
  });

});